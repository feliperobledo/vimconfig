; extends

; Match an assignment where the comment is immediately above it
((comment) @injection.language
 (#match? @injection.language "#\\s*language=\\w+")
 .
 (assignment
   right: (string
     (string_content) @injection.content))
 (#gsub! @injection.language "^#\\s*language=(%w+)" "%1")
 (#downcase! @injection.language))

; Match a standalone expression string (like a docstring)
((comment) @injection.language
 (#match? @injection.language "#\\s*language=\\w+")
 .
 (expression_statement
   (string
     (string_content) @injection.content))
 (#gsub! @injection.language "^#\\s*language=(%w+)" "%1")
 (#downcase! @injection.language))
