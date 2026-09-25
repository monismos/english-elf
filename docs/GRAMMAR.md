# ENGLISH-ELF Natural Language Grammar (v1.0)

## Philosophy
English-ELF parses natural English sentences. The goal is to make programming feel like speaking to a computer in everyday English.

## Lexical Structure

### Tokens
- WORD: alphabetic sequences, hyphens allowed
- NUMBER: integers and decimals
- STRING: quoted text in "..."
- PUNCT: . , ; : ! ? 
- EOF: end of file

### Articles (silent)
`a`, `an`, `the` - skipped during parsing but help natural flow.

## Statements

### Output Statements
```
Say <expression>.
Tell <expression>.
Print <expression>.
Display <expression>.
Shout <expression>.
Output <expression>.
Speak <expression>.
Announce <expression>.
Yell <expression>.
Whisper <expression>.  # quiet output
Mumble <expression>.   # debug output
```

Multiple expressions (comma or "and" separated):
```
Say hello, world.
Tell name and age.
```

### Variable Assignment
```
Set <name> to <expression>.
Let <name> be <expression>.
Make <name> equal <expression>.
Call <name> <expression>.  # nickname assignment
<name> should be <expression>.  # imperative
```

Variable name is a single word (no spaces).

### Expressions (Implicit Interpolation)
```
hello world        # string with spaces - natural interpolation
name               # variable lookup or bare word
"x"                # quoted string literal
123                # number literal
```

Natural word blending:
```
Set greeting to Hello, name.  # "Hello, " + value of name
Tell greeting world.          # "greeting world" - each checked, then combined
```

### List Operations
```
Create a list named <name>.
Make a list called <name>.
Define a list named <name>.

Add <value>, <value>, and <value> to <list>.
Append <value> to <list>.
Put <value> in <list>.
Insert <value> into <list>.

Take <value> from <list>.      # remove
Remove <value> from <list>.
Clear the list.                 # empty
Show the list.                  # print all
Count the list and call it n.   # get length
```

### For-Each Loop
```
For each <var> in <list>, <body>.
For every <var> in <list>, <body>.
Every item in <list>: <body>.
Each <var> in <list>: <body>.
```

Body can be multiple statements separated by newline or semicolon.

### Conditionals
```
If <condition>, <body>.
Unless <condition>, <body>.
When <condition>, <body>.
Whenever <condition>, <body>.  # repeat while true

<condition> ::= <expression> <comparator> <expression>
             | <expression> is <comparison>
             | <expression> is at most <expression>
             | <expression> is at least <expression>
             | <expression> is greater than <expression>
             | <expression> is less than <expression>
             | the list is not empty
             | <variable> exists

<comparator> ::= equals | is | ==  (equals)
               not equals | != | isn't | is not
               greater than | > | is more than | is above
               less than | < | is at most | is below | is under
               at least | >= | is no less than
               at most | <= | is no more than
```

Extended conditionals:
```
If x is at most 5:
    Say it is small.
    Let result be small.
Finish.  # end block

Else:
    Say it is big.
Finish.

# Single line:
If x equals 5, say big.
```

### While Loops
```
While <condition>, <body>.
As long as <condition>, <body>.
Keep doing: <body>. While <condition>.
Repeat <count> times: <body>.
Loop forever: <body>.
```

### Functions
```
To calculate <name>: <body>.
To compute <name>: <body>.
To get <name>: <body>.
To find <name>: <body>.

To calculate factorial of n:
    If n is at most 1, return 1.
    Return n times call factorial with n minus 1.
Finish.

To process items:
    Each item:
        Display item.
    Done.
Finish.

# Call:
Calculate factorial of 5.
Process items.
```

Function with parameters:
```
To greet person named greeting:
    Say greeting, person.
Finish.
```

### Return Statements
```
Return <expression>.
Send back <expression>.
Give <expression>.  # synonym
```

### Exit/Stop
```
Stop.
Halt.
End the program.
Quit.
Exit.
That's all.
Done.
```

### Natural Actions (Implicit Functions)
```
Greet <someone>.                      # Say "Hello, <someone>!"
Hello <someone>.                    # Same
Goodbye <someone>.                  # Say "Goodbye, <someone>!"
Welcome <someone>.                  # Say welcome message
Thanks.                             # Acknowledge
Please.                               # Polite (no-op or emphasis)
Sorry.                                # Error acknowledgment
```

## GenZ/Slang Extensions

### Booleans/Assertions
```
Yeah, that's true.       # Assert/affirm
Nah, that's false.       # Negate
Facts.                     # True
Cap.                       # Lie/L false
No cap.                    # Actually true
Bet.                       # Confirmation
Sheesh.                    # Expression/disbelief
It's giving <emotion>.     # Describe state (it's giving confused = error)
Period.                    # Emphasis (final statement)
Sksksk.                    # Excited approval
Slay.                      # Success
Yeet.                      # Force/exit
```

### Emphasis Modifiers
```
Please, say hello.         # Polite request
Pretty please, do it.       # Strong emphasis
Literally, that is wrong.  # For real
Obviously, x is 5.         # Obviously
Honestly, I think x.       # Honestly
```

### Informal Questions
```
What's good?               # Environment check
What's poppin?             # Status query
How's it going?            # General status
What's the vibe?           # Mood/status
```

## Implicit Conversions

### String Interpolation
Variables in strings are implicitly looked up:
```
Set greeting to Hello, name.   # "Hello, " + value of name
Say "Hello, name."           # Quoted = literal, no interpolation
```

### Numeric Context
```
Set x to five.               # "five" -> 5
Set y to one hundred.        # "one hundred" -> 100
```

## Special Variables/References

```
the list                     # Most recently created list
it                           # Previous result/value
this                         # Current context
that                         # Referenced value
```

## Comments
```
# This is a comment
This is also a comment.      # Lines starting with #
```

## Future Extensions

### File I/O
```
Read file "path".
Write "<text>" to file "path".
Load JSON from "data.json".
Save to "output.json".
```

### HTTP
```
Get the webpage at "https://...".
Post to "https://..." with data.
Listen on port 8080.
Respond with "Hello".
```

### Concurrency
```
Meanwhile: <background task>.
Wait for all tasks.
That's all of them.
```

## Grammar BNF

```
program          ::= statement* EOF
statement        ::= output_stmt
                  | assignment_stmt
                  | list_stmt
                  | for_each_stmt
                  | if_stmt
                  | while_stmt
                  | function_stmt
                  | return_stmt
                  | natural_action
                  | slang_stmt

output_stmt      ::= output_verb expr_list "."
output_verb      ::= "say" | "tell" | "print" | "display" | "shout" | "output" | "speak" | "announce" | "yell" | "whisper" | "mumble"

assignment_stmt  ::= ("set" | "let" | "make") NAME ("to" | "be" | "equal") expression "."

expr_list        ::= expression ("," expression | "and" expression)*

expression       ::= WORD+  # natural string/interpolation
                  | NUMBER
                  | STRING
                  | WORD     # single word (variable or bare)

list_stmt        ::= ("create" | "make" | "define") list_phrase NAME "."
list_phrase      ::= ("a" | "an")? "list" ("named" | "called")?

for_each_stmt    ::= ("for" "each"? | "every" | "each") NAME ("in" | "from") expression ":" statement
                  | ("for" "each" | "every") NAME "in" expression "," statement "."

if_stmt          ::= ("if" | "unless" | "when") condition ":" block
                  | ("if" | "unless" | "when") condition "," statement "."

condition        ::= expression comparators expression

function_stmt    ::= "to" ("calculate" | "compute" | "get" | "find") NAME (":" | ".") block

block            ::= statement+ "finish."

natural_action   ::= "greet" expression "."
                  | "hello" expression "."
                  | "goodbye" expression "."
                  | "thank" "you" "."
```

## Examples

### Hello World Variants
```
Say hello world.
Greet the world.
Hello there.
What's up?
```

### Fibonacci (Natural)
```
Create a list for fibonacci.
Start with 1 and 1.
Each next:
    If the list is at least 100, stop.
    Say the last two numbers and add them.
Done.
```

### Function Definition
```
To check if n is even:
    If n divided by 2 equals 0, return yeah.
    Return nah.
Finish.
```