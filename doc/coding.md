Coding style
====================

- K&R Stroustrup variant
- 2 space indenting, no tabs
- Each function has its opening brace at the next line on the same indentation level as its header, the statements within the braces are indented, and the closing brace at the end is on the same indentation level as the header of the function at a line of its own. The blocks inside a function, however, have their opening braces at the same line as their respective control statements; closing braces remain in a line of their own.
- Else is on the same indentation level as its accompanying ```if``` statement at a line of its own.
- Curly brackets even for one-line blocks
- No extra spaces inside parenthesis; please don't do ```( this )```
- No space after function names, one space after ```if```, ```for``` and ```while```

```c++
int main(int argc, char *argv[])
{
  ...
  while (x == y) {
    something();
    somethingelse();
  
    if (some_error) {
      do_correct();
    } 
    else {
      continue_as_usual();
      return false;
    }
  }

  finalthing();
  ...
}
```

A-Style example command line:
```
--style=stroustrup --indent=spaces=2 --break-closing-brackets --add-brackets --convert-tabs --mode=c
```
