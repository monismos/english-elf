# Natural Language Tests (v0.5 - Linux/C)

> **v0.5 status**: `test_say.txt`, `test_variables.txt`, `test_lists.txt`/`test_create_list.txt`, `test_for_each.txt`, `test_natural.txt` are **supported** (13 tests). `test_conditionals.txt`, `test_loops.txt`, `test_slang.txt`, `test_functions.txt` are **future** (in `tests/future/`) and expected to fail with `Unknown statement`.

# Natural Language Tests

## Output Tests (test_say.txt)
```
Say hello world.
Tell everyone hello.
Shout hello at the world.
Display hello.
Output hello.
Speak hello.
Announce hello.
Yell hello.
Whisper secret.
Mumble debug info.
```

## Variable Tests (test_variables.txt)
```
Set x to 5.
Let y be 10.
Make z equal twenty.
Print x y and z.
Set greeting to Hello, friend.
Let name be Alice.
Greet name.
```

## List Tests (test_lists.txt)
```
Create a list named numbers.
Make a list called primes.
Define a list named fib.

Add 1, 2, 3, and 4 to numbers.
Append 5 to primes.
Put 6 in fib.
Insert 7 into numbers.

Show the list.
Say the list.
Display primes.
Print numbers, primes, and fib.
```

## For-Each Tests (test_for_each.txt)
```
Create a list named items.
Add one, two, and three to items.

For each n in items, say n.
Every item in items: display item.
Each element in the list: tell element.
```

## Natural Phrasing Tests (test_natural.txt)
```
Set greeting to Hello, world.
Print greeting everyone.
Say greeting world.

Create a list named friends.
Add Alice, Bob, and Charlie to friends.
Everyone in friends: greet them.
```

## Conditional Tests (test_conditionals.txt)
```
Set x to 5.
If x is at most 5, say it is small.
Unless x is at least 10, say it is not big.
When x equals 5, say five.
```

## GenZ Slang Tests (test_slang.txt)
```
Bet.
Facts.
No cap.
Sheesh.
Slay.
Yeah, that works.
Nah, try again.
```

## While Loop Tests (test_loops.txt)
```
Set n to 0.
While n is less than 5:
    Say n.
    Let n be n plus 1.
Done.

Repeat three times:
    Greet world.
Finish.
```

## Function Tests (test_functions.txt)
```
To double n:
    Return n times 2.
Finish.

Let result be double of 5.
Print result.

To check if n is even:
    If n divided by 2 equals 0, return yeah.
    Return nah.
Finish.
```