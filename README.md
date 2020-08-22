# DelphiJSON
An explicit and configurable single file JSON library for Delphi that is based on attributes and RTTI.

![DelphiJSONLogo](https://github.com/gruco0002/DelphiJSON/blob/master/Logo/Logo_small.png?raw=true)

The library is based on Delphis `System.RTTI` and `System.JSON` and has no non-standard dependencies.
The test framework used to develop and test the library is `DUnitX`, but it is not required if you just want to use the library.

## Why
The standard JSON (de)serialization provided with `System.JSON` is robust, but has its problems with arbitrary data formats.
Furthermore it does not allow for an easy Opt-In/Out for data fields that should not be (de)serialized.
In order to gain more control over the whole process, this library was developed.
It allows for explicit JSON names, needs an explicit opt-in to (de)serialize data and supports types like TDateTime and most of the `System.Generics.Collections` classes.

Decoupling the implementation names of your Delphi objects or records from the JSON name is especially helpful for consistency.
E.g. you provide a JSON api with your application and at some point a simple refactoring, i.e. renaming a field of a class somewhere in the source code, causes your api to change, since the name of the implemented field was tied to the name used in (de)serialization.
By using explicit JSON names this would not happen by accident, allowing for a more consistent api.

## Getting Started

Since this is a single source file library, it is sufficient if you just download the `DelphiJSON.pas` file from a release or the master branch of the repository.

### Install
You can either 'install' the library inside a specific project (1) or for your whole environment (2).

#### Specific Project
Copy the file to your project folder and add it as Unit to your project. Then you should be ready to go.

*Alternatively* save the unit file (`DelphiJSON.pas`) to a fixed location (this can be outside your project directory). Select your project and open its options (`Project` -> `Options`). Go to the `Delphi-Compiler` section and add the directory in which you placed the unit to the `Search Path`.

#### Environment
To install the library for the whole Delphi environment on your pc, save the unit file (`DelphiJSON.pas`) to a fixed location. Then add the directory, in which you placed the unit to the global search path and library path of the compiler. For RadStudio this would be under `Tools` -> `Options` -> `Language` -> `Delphi` (Make sure the correct platform is selected). 

### Use

TODO


## Further Information

TODO
