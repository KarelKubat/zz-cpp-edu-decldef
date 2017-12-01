# Definition vs. Declaration

When the C++ compiler comes code that calls a function, then that type or
function must be known to the compiler in advance - otherwise, the compiler
couldn't verify proper calling, number of parameters and so on.  That function
must be previously **declared** to the compiler.

The actual code that forms that function is called the **definition**. It may be
located in a different source file (maybe to be compiled later as part of the
same project), or you even might not have access to it when only its compiled
form is present in library.

Declaring vs. definining comes into play when working on a larger,
multi-source-file project.

## External Functions

Consider this one-source-file example:

```c++
#include <iostream>

void test() {
  std::cout << "Test function called\n";
}

int main() {
   test();
   return 0;
}
```

Possibly this is how you started out creating your first C++ programs: all
that's necessary for your program in one source file and functions that are
called later-on occur higher up in the file.

Now imagine that `test()` isn't just a silly function but something that you
want to make available to other people or to your other programs. At that time
you might want to place the code for `test()` into its own source. Here is a
simplistic example which, although it works, isn't good practice.

```c++
// File: test.cc
#include <iostream>

void test() {
  std::cout << "Test function called\n";
}
```

```c++
// File: main.cc
extern void test();

int main() {
   test();
   return 0;
}
```

Although the organization into files isn't optimal, this example does illustrate
the basics:

*  The utility code (here: function `test()`) is located in its own source
   file (here `test.cc`)
*  Anyone who wants to use it, declares the function as `external` and can
   then call it.

So to stay in terminology, function `test()` is:

*  Defined in `test.cc`
*  Declared (and called) in `main.cc`

## Headers

The above example isn't good practice because the author of `main.cc` has to
declare the test function. Wouldn't it be nice to provide something for that?
That is what header files are for: the author can include them and thus
declare loads of utility functions at the same time.

In the simplistic example, the code organization would be:

```c++
// Header file: test.h
extern void test();
```

```c++
// Implementation of test() in test.cc
#include <iostream>
#include <test.h>

void test() {
  std::cout << "Test function called\n";
}
```

```c++
// Calling the test function: main.cc
#include <test.h>

int main() {
   test();
   return 0;
}
```

And that is basically all there's to it.

A few remarks:

*  The declaration file `test.h` is included in both `test.cc` and in
   `main.cc`. Including it also in `test.cc` provides some extra checks against
   typos. E.g., if `test.cc` where to say `int test()` then the compiler would
   show an error, because the previously seen declaration from `test.h` is
   claiming `void test()`.

*  The standard C++ header `iostream` is included only where it's needed: in
   `test.cc`. The code would also work if the inclusion of `iostream` where in
   `test.h`, but then every compilation of a sourcefile that included `test.h`
   would also have to parse `iostream`. (Just think of all the nanoseconds
   that are saved by putting the `#include` statement in the right place.)

*  Sometimes headers for C++ lack an extension (as in `iostream`), or they are
   named `.hpp` (presumably for plus-plus) or even `.hh`. It doesn't really
   matter, it's just a question of personal taste.

## Inclusion guarding in headers

Once you create a header file for inclusion by other headers or sources, then
you will most likely want to add guards to prevent re-inclusion. Basically, you
want that a source file like the following gets compiled correctly:

```c++
#include <myheader>
#include <myheader>
```

This is of course a trivial example where it's plainly visible that one of the
`#include` directives is redundant. But once such directives occur in other
headers, which are included in even more headers.. then it gets hard to keep
track.

Note that there wouldn't be a problem with the above shown `test.h`:
re-declaring a function `void test()` isn't an error in itself. But consider
what happens when the header file also defines something, as in:

```c++
// Sample header that defines things
#define MAX_LENGTH 1024
struct Coord {
  double x, y;
};
```

Then, re-including would cause the compiler to complain about a redefinition,
which is an error.

Guarding headers against a second inclusion is trivial and is entirely done
by the preprocessor:

*  Determine some preprocessor symbol for guarding. Often, this symbol is
   chosen as an underscore, followed by the header filename in caps, followed
   by another underscore, then `INCLUDED` and finally one closing underscore.
   For example, for a file `myheader.h` this would be `_MYHEADER_H_INCLUDED_`,
   but you can choose whatever symbol you like, as long as it doesn't conflict
   with other similar defined symbols.
*  The header must only be processed when `#ifndef` that-symbol applies.
*  The first action of processing the header is to `#define` that-symbol
   so that during a second inclusion the `#ifndef` fails.
*  The header is terminated with an `#endif` to match the `#ifndef`.

For example:

```c++
#ifndef _MYHEADER_H_INCLUDED_
#define _MYHEADER_H_INCLUDED_

/*
 * Body of myheader.h goes here
 */

#endif // _MYHEADER_H_INCLUDED_
```

## One function per file?

It may look tempting to put more functions in a file; you might think that you'd
find your source code quicker that way. For example, consider the example below.

```c++
// Declarations in one header (test.h)
#ifndef _TEST_H_INCLUDED_
#define _TEST_H_INCLUDED_

void hello();
void goodbye();

#endif // _TEST_H_INCLUDED_
```

```c++
// Support functions definitions (test1.cc)
#include <test.h>
#include <iostream>

void hello() {
  std::cout << "Hello\n";
}

void goodbye() {
  std::cout << "Goodbye\n";
}
```

```c++
// Caller (main.cc)
#include <test.h>

int main() {
  // Call only one function that's declared in test.h
  goodbye();

  return 0;
}
```

If we want to emulate a *real* build cycle, then we should put the compiled
result of `test.cc` (which is an object file `test.o`) into a library, say
`libtest.a` and link it into the compilation of `main.cc`.

```shell
$ cc -c test1.cc
$ ar rvs libtest1.a test1.o
$ cc -o main main.cc -ltest1
```

The reason that this example is wrong is the following. During the linkage phase
that produces the executable `main` all necessary **objects** are taken from
`libtest.a` and used. Since function `goodbye()` is needed, `test.o` is
taken. This object unfortunately also holds the code for `hello()` which is not
necessary, but is included as excess baggage.

The solution for this is of course to split `test.cc` into two files, one
holding function `hello()` and the other holding function `goodbye()`:

```c++
// Function hello() (test2a.cc)
#include <iostream>
#include <test.h>

void hello() {
  std::cout << "Hello\n";
}
```

```c++
// Function goodbye() (test2b.cc)
#include <iostream>
#include <test.h>

void goodbye() {
  std::cout << "Goodbye\n";
}
```

Producing a binary now involves a `libtest.a` holding two objects and producing
a smaller binary:

```shell
$ cc -c test2a.cc test2b.cc
$ ar rvs libtest2.a test2a.o test2b.o
$ cc -o main main.cc -ltest2
```

So, as a general rule, when organizing reusable code put each function in its
own source file. Often you don't know in advance whether you will reuse the code
later; so this general rule usually becomes: just put every function in its own
source file.
