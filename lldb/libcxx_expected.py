"""LLDB formatter for libc++ ``std::expected`` (LLDB 22 has none built in).

Shows a summary (``has value`` / ``has error``) and a single ``Value`` or ``Error``
child that keeps its own formatter. ``expected<void, E>`` shows no child in the
value state.

Loaded by Vimspector's lldb-dap adapter (``lua/plugins/vimspector.lua``) through
``initCommands``. By hand: ``command script import <path>/libcxx_expected.py``.
"""

import lldb

CATEGORY = "libcxx-expected"
# The inline namespace is optional: LLDB matches both the real name
# (std::__1::expected<...>) and the display name (std::expected<...>).
TYPE_REGEX = r"^std::(__[[:alnum:]]+::)?expected<.+>$"

# libc++ nests these a few levels deep, and the nesting changes with the types
# (tail-padding reuse, trivial destructors, void), so search by name.
_HAS_VAL = "__has_val_"
_VAL = "__val_"
_UNEX = "__unex_"
# Real layouts put them at depth 4-5; the cap bounds the walk on unknown layouts.
_MAX_DEPTH = 6

UNKNOWN_LAYOUT = "<unknown expected layout>"


def _find_members(valobj):
    """Breadth-first search for the three members. Missing ones stay None."""
    found = {_HAS_VAL: None, _VAL: None, _UNEX: None}
    queue = [(valobj, 0)]
    while queue and None in found.values():
        node, depth = queue.pop(0)
        for i in range(node.GetNumChildren()):
            child = node.GetChildAtIndex(i)
            if not child.IsValid():
                continue
            name = child.GetName()
            if name in found:
                if found[name] is None:
                    found[name] = child
                # Don't descend into the payload: a nested expected would match too.
                continue
            # expected stores its members inline. Following pointers on an unknown
            # layout would read arbitrary (possibly uninitialised) memory.
            child_type = child.GetType()
            if child_type.IsPointerType() or child_type.IsReferenceType():
                continue
            if depth + 1 < _MAX_DEPTH:
                queue.append((child, depth + 1))
    return found


def _is_void_value(valobj):
    # Strip typedefs and const so `IntResult` / `const expected<...>` work.
    t = valobj.GetType().GetUnqualifiedType().GetCanonicalType()
    arg = t.GetTemplateArgumentType(0)
    return arg.IsValid() and arg.GetName() == "void"


class _State:
    """The decoded state of one expected, or `ok = False` for an unknown layout."""

    def __init__(self, valobj):
        raw = valobj.GetNonSyntheticValue()
        members = _find_members(raw)
        has_val = members[_HAS_VAL]
        self.is_void = _is_void_value(raw)
        self.ok = False
        self.has_value = False
        self.payload = None
        if has_val is None:
            return
        error = lldb.SBError()
        flag = has_val.GetData().GetUnsignedInt8(error, 0)
        if error.Fail():
            return
        self.has_value = flag != 0
        if self.has_value:
            if self.is_void:
                self.ok = True
            elif members[_VAL] is not None:
                self.ok = True
                self.payload = members[_VAL]
        elif members[_UNEX] is not None:
            self.ok = True
            self.payload = members[_UNEX]


def summary(valobj, internal_dict):
    try:
        state = _State(valobj)
    except Exception:  # A formatter must never take the variables view down.
        return UNKNOWN_LAYOUT
    if not state.ok:
        return UNKNOWN_LAYOUT
    return "has value" if state.has_value else "has error"


class ExpectedSynthProvider:
    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.child = None
        self.raw = None

    def update(self):
        self.child = None
        self.raw = None
        try:
            state = _State(self.valobj)
        except Exception:
            state = None
        if state is None or not state.ok:
            # Unknown layout: show the real members so nothing is hidden.
            self.raw = self.valobj.GetNonSyntheticValue()
        elif state.payload is not None:
            # Clone keeps the member's location and type, so LLDB applies its
            # own formatter (std::string -> "bad", vector -> size=3 {...}).
            name = "Value" if state.has_value else "Error"
            self.child = state.payload.Clone(name)
        # False: re-run update on every stop, since the state can change.
        return False

    def num_children(self):
        if self.raw is not None:
            return self.raw.GetNumChildren()
        return 1 if self.child is not None else 0

    def get_child_index(self, name):
        if self.raw is not None:
            return self.raw.GetIndexOfChildWithName(name)
        if self.child is not None and name == self.child.GetName():
            return 0
        return -1

    def get_child_at_index(self, index):
        if self.raw is not None:
            return self.raw.GetChildAtIndex(index)
        if index == 0:
            return self.child
        return None

    def has_children(self):
        return self.num_children() > 0


def __lldb_init_module(debugger, internal_dict):
    module = __name__
    debugger.HandleCommand(
        'type synthetic add -w %s -l %s.ExpectedSynthProvider -x "%s"'
        % (CATEGORY, module, TYPE_REGEX)
    )
    # -e: without it a summary hides the synthetic children.
    debugger.HandleCommand(
        'type summary add -w %s -e -F %s.summary -x "%s"' % (CATEGORY, module, TYPE_REGEX)
    )
    debugger.HandleCommand("type category enable %s" % CATEGORY)
