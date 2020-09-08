<img align="right" alt="DelphiJSONLogo" src="https://github.com/gruco0002/DelphiJSON/blob/master/Logo/Logo_small.png?raw=true"></img>

# DelphiJSON
An explicit and configurable single file JSON library for Delphi that is based on attributes and RTTI.

The library is based on Delphis `System.RTTI` and `System.JSON` and has no non-standard dependencies.
The test framework used to develop and test the library is `DUnitX`, but it is not required if you just want to use the library.

## Why
The JSON (de)serialization using only `System.JSON` is a tideous job, since every field has to be filled in by hand.
The standard JSON (de)serialization provided with `REST.Json.TJson` is robust and can (de)serialize JSON into Delphi data types. But it has some problems with arbitrary data formats. 

Furthermore it does not allow for an easy Opt-In/Out for data fields that should not be (de)serialized. Additionally the
JSON field names are tied to the Delphi source code, which can lead to problems.
In order to gain more control over the whole process, this library was developed.
It allows for explicit JSON names, needs an explicit opt-in to (de)serialize data and supports types like TDateTime and most of the `System.Generics.Collections` classes.

Decoupling the implementation names of your Delphi objects or records from the JSON name is especially helpful for consistency and can be seen as improving on the principle 'seperation of concerns'.
E.g. you provide a JSON api with your application and at some point a simple refactoring, i.e. renaming a field of a class somewhere in the source code, causes your api to change, since the name of the implemented field was tied to the name used in (de)serialization.
By using explicit JSON names this would not happen by accident, allowing for a more consistent api and less errors.

By introducing explicit naming, converters, default values, null checks, (not) required values and other things using attributes, this library tries to improve upon the named problems, make it easier for developers to get started with JSON (de)serialization and helps to abstract the (de)serialization logic away from the underlying data model and its business logic leading to cleaner and more readable code.

## Getting Started

Since this is a single source file library, it is sufficient if you just download the `DelphiJSON.pas` file from a release (or if you are daring the master branch) of the repository.

### Install
You can either 'install' the library inside a specific project or for your whole environment.

#### Specific Project
Copy the file to your project folder and add it as Unit to your project. Then you should be ready to go.

*Alternatively* save the unit file (`DelphiJSON.pas`) to a fixed location (this can be outside your project directory). Select your project and open its options (`Project` -> `Options`). Go to the `Delphi-Compiler` section and add the directory in which you placed the unit to the `Search Path`.

#### Environment
To install the library for the whole Delphi environment on your pc, save the unit file (`DelphiJSON.pas`) to a fixed location. Then add the directory, in which you placed the unit to the global search path and library path of the compiler. For RadStudio this would be under `Tools` -> `Options` -> `Language` -> `Delphi` (Make sure the correct platform is selected). 

### How to use
To use the library add `DelphiJSON` to your uses in the respective unit.

After that start anotating your classes or records. An example would be:
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('textField')]
    testText: string;

    testTextNotSer: string;

    [DJValue('boolField')]
    testBool: boolean;

    [DJValue('int')]
    testInt: Integer;

  end;
```

Every field that should be (de)serialized has to be annotated with the `DJValue` attribute that also contains the JSON name of this field. The JSON name (e.g. `boolField` is the JSON name of the Delphi field `testBool`) does not have to be the same as the Delphi name of the field. Fields that do not have the `DJValue` attribute will be ignored by the (de)serializer.

Furthermore add the `DJSerializable` attribute to the record or class if it should be (de)serializable.
**Note:** All records or classes that should be (de)serializable have to be annotated with the `DJSerializable` attribute, otherwise an error message will be raised upon (de)serialization.

To serialize data call the `DelphiJSON<T>.Serialize` function.
It is important to use the correct type! The result of the serialization is a string containg the JSON data.
An example would be (For further examples have a look in the test units):
```pascal
procedure SerializeMyData(data: TTestClass);
var
    serialized: string;
begin
    serialized := DelphiJSON<TTestClass>.Serialize(data);
    WriteLn(serialized);
end;
```


To deserialize an object call the `DelphiJSON<T>.Deserialize` function. It returns the respective type and takes the JSON data as a string parameter. Be sure to use the correct type! An example would be:
```pascal
function DeserializeMyData(jsonString: string) : TTestClass;
begin
    Result := DelphiJSON<TTestClass>.Deserialize(jsonString);
end;
```

Also other data (not only your own objects) can be (de)serialized. The following shows a few examples for the serialization (deserialization works vice versa):
```pascal
uses DelphiJSON, System.Generics.Collections, System.SysUtils, System.DateUtils;

procedure SerializeExample;
var
    list: TList<string>;
    serializedList: string;

    dt: TDateTime;
    serializedDateTime: string;

    dict: TDictionary<TDateTime, string>;
    serializedDict: string;
begin
    // list example
    list := TList.Create;
    list.Add('Hello');
    list.Add('World');
    list.Add('!');
    
    serializedList := DelphiJSON<TList<string>>.Serialize(list);
    WriteLn(serializedList);

    // date time example
    dt := EncodeDateTime(2020, 4, 23, 10, 12, 11, 154);
    
    serializedDateTime := DelphiJSON<TDateTime>.Serialize(dt);
    WriteLn(serializedDateTime);

    // dictionary example
    dict := TDictionary<TDateTime, string>.Create;
    dict.Add(EncodeDateTime(2020, 4, 23, 10, 12, 11, 154), 'April was nice!');
    dict.Add(EncodeDateTime(2020, 8, 23, 10, 12, 11, 154), 'August was hot!');
    dict.Add(Now, 'The current time.');

    serializedDict := DelphiJSON<TDictionary<TDateTime, string>>.Serialize(dict);
    WriteLn(serializedDict);
end;
```

## Examples and Documentation
Examples and documentation can be found in the [EXAMPLES.md](EXAMPLES.md) file.
Another good source for information is the interface part of the library's
source code in the `DelphiJSON.pas` file and the test cases in the `Tests` folder.

## Further Information
This project/library is licensed under the MIT License (see `LICENSE` file).
If you find bugs, memory leaks or other errors feel free to open an issue.
New ideas, improvements and suggestions can also be added as an issue. In general feedback is welcome!

If you use the library or like it, it would be nice if you leave a star :star: for this repository.
Although you do not have to inform me if you use the library, feel free to do so (publicly or private) :smile:
