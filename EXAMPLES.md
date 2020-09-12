# Examples and Documentation
This file contains basic examples and documentation of the library.
Another good source for information is the interface part of the library's
source code in the `DelphiJSON.pas` file and the test cases in the `Tests` folder.

Important things will be marked with the :warning: symbol.

This documentation is not be complete and will be extended over time.

## Serialize
To serialize data call the `DelphiJSON<T>.Serialize` function.
It is important to use the correct type! The result of the serialization is a string containg the JSON data.
```pascal
procedure SerializeMyData(data: TTestClass);
var
    serialized: string;
begin
    serialized := DelphiJSON<TTestClass>.Serialize(data);
    WriteLn(serialized);
end;
```
You can serialize nearly any data (including Arrays, Lists, Dictionaries, DateTimes):
```pascal
procedure SerializeMyData(data: string);
var
    serialized: string;
begin
    serialized := DelphiJSON<TTestClass>.Serialize(data);
    WriteLn(serialized);
end;
```
:warning: Before serializing custom data structures like classes or records,
be sure to annotate the fields and types with the correct attributes.

## Deserialize
To deserialize an object call the `DelphiJSON<T>.Deserialize` function. It returns the respective object and takes the JSON data as a string parameter. Be sure to use the correct type! An example would be:
```pascal
function DeserializeMyData(jsonString: string) : TTestClass;
begin
    Result := DelphiJSON<TTestClass>.Deserialize(jsonString);
end;
```
As with the serialization nearly any data can be deserialized.

:warning: Before deserializing custom data structures like classes or records,
be sure to annotate the fields and types with the correct attributes.

:warning: Be sure to have a suitable constructor for the deserialization if deserializing classes.
More information can be found in the section for the `DJConstructorAttribute`.

## Attributes
This library uses attributes for classes and records to determine how and what should be (de)serialized.
Attributes are used to annotate classes, records, fields and other parts of the source code.
An annotation looks as follows `[DJSerializableAttribute]`, but can also be written in short as `[DJSerializable]`.

The parameters of the constructor of such an attribute have to be constant values and are given in brackets without
mentioning the `Create` constructor: `[DJValue('valueName')]`.

A with attributes annotated class can look as follows:
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

The DelphiJSON library currently provides the following attributes:
* DJValueAttribute
* DJSerializableAttribute
* DJNonNilableAttribute
* DJConstructorAttribute
* DJDefaultValueAttribute
* DJDefaultOnNilAttribute
* DJRequiredAttribute

## DJSerializableAttribute
This attribute is *required* to explicitly state, that a record or class should be (de)serializable. This behaviour can be turned of in the TDJSettings, but this is not recommended.
An example for a class and a record: 
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

  end;

  [DJSerializable]
  TTestRecord = record

  end;
```
:warning: An error will be thrown if the attribute is not present during (de)serialization.

## DJValueAttribute
This attribute is *required* to explicitly state, that a field of a record or class should be (de)serialized.
It also defines the JSON name for this field. The JSON name is the name of the respective field in the JSON object.
It does not have to be the same as the Delphi field name. However it has to be *unique*. The annotated fields have to
be public or published, otherwise RTTI can not find them and will ignore them completely.


A simple example for a class with fields that are annotated with the `DJValue` attribute:
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('testText')]
    testText: string;

    testTextNotSer: string;

    [DJValue('boolField')]
    testBool: boolean;

    [DJValue('int')]
    testInt: Integer;

  end;
```
In this example all fields, except for the `testTextNotSer` field are going to be (de)serialized. The respective
JSON data could look like that:
```JSON
{
    "testText": "Hello World",
    "boolField": true,
    "int": 123
}
```

:warning: Only fields (no properties) are supported, field names have to be unique and fields have to be public or published.

## EDJError
If something goes wrong during deserialization an EDJError will be raised. Before the error reaches outside of
the library, all created data will be cleaned up s.t. there will be no memory leakage.
There are different types of errors that are derived from the EDJError.
The different types can be used to track down different error causes:
* EDJRequiredError
* EDJNilError
* EDJWrongArraySizeError
* EDJCycleError
* EDJFormatError

You can catch certain errors to track down incorrect input data (e.g. missing fields, etc.):
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('value')]
    testText: string;

    [DJValue('int')]
    testInt: Integer;

  end;


function Demo(inputJSON: string) : TTestClass;
begin
  try
    Result := DelphiJSON<TTestClass>.Deserialize(inputJSON);
  except
    on e: EDJRequiredError do
    begin
      WriteLn('One of the required field "value" or "int" was' +
              ' not present in the JSON data!');
      Result := nil;
    end;
  end;
end;
```


### EDJRequiredError
This error is raised if an required field is not found in the JSON object.
### EDJNilError
This error is raised if a field is nil/null although it is annotated with
the DJNonNilableAttribute.
### EDJWrongArraySizeError
This error is raised if a fixed sized array is being deserialized and the
size of the array in the JSON data does not match the delphi fixed array
size.
### EDJCycleError
This error is raised if a reference cycle during serialization is detected.
A reference cycle can occur if fields that are serialized point towards
objects that have already been serialized or are in the process of being
serialized.
### EDJFormatError
This error is raised if a wrong format of the JSON data is provided during
deserialization.
E.g.: A DateTime string should be deserialized but does not meet the
requirement of the ISO 8601 format.

## DJConstructorAttribute
This attribute can be used to explicitly use a constructor of a class for
deserialization.
If no constructor has this attribute, the default `Create` constructor will
be tried to use.
Note that all constructors that are used for (de)serialization are not allowed
to take in any arguments (including ones with a default value).

In the following example the default `Create` constructor is being used.
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('testText')]
    testText: string;

    constructor Create;

  end;
```

In the following example the annotated `FromJSON` constructor is being used.
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('testText')]
    testText: string;

    constructor Create;

    [DJConstructor]
    constructor FromJSON;

  end;
```

In the following example the annotated `Create` constructor is being used, since this is the default:
```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('testText')]
    testText: string;

    constructor Create;

    constructor FromJSON;

  end;
```

:warning: Without the DJConstructorAttribute the default `Create` constructor is used.

:warning: Constructors have to be public or published. Otherwise the deserializer can not find them.

:warning: Only annotate one constructor with the DJConstructorAttribute.

:warning: A constructor being used by (de)serialization should not write to
fields that are going to be filled by the deserializer. This could cause
data loss and memory leaks.


## DJRequiredAttribute
By default all fields that are annotated with the `DJValue` attribute are required to be
present in the JSON data upon deserialization. If a field is not found in the JSON data an
EDJRequiredError is being raised.
This behaviour can be changed via the DJSettings or with the DJRequired attribute.
The attribute itself takes in a boolean that states if the field is required. This overrides
any settings imposed upon the deserialization process through the DJSettings.
If a field is not required and it is not present in the JSON data, it will remain untouched
by the deserializer. An example for using the attribute:

```pascal
uses DelphiJSON;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('testText')]
    [DJRequired(false)]
    testText: string;

    [DJValue('int')]
    [DJRequired]
    testInt: Integer;

    [DJValue('time')]
    otherValue: TDateTime;

  end;
```
The `testText` field will never be required to be present in the JSON data. The `int` field always
has to be present, otherwise an `EDJRequiredError` will be thrown. The `time` field is required by
default if not changed by the DJSettings.

:warning: The DJRequired attribute only has an effect if used together with the DJValue attribute.

:warning: The DJRequired attribute always overrides the settings opposed by DJSettings for the annotated field.

## TDJSettings
The TDJSettings object can be used to control the (de)serialization. It is an optional argument to the
`Serialize` and `Deserialize` function. If not specified or nil, the default settings will be used.
The settings object can be created by calling the `Default` constructor.

An example for using the settings to disable all fields being required by default:
```pascal
procedure Example(jsonData: string);
var
  settings: TDJSettings;
  tmp: TTestClass;
begin
  settings := TDJSettings.Default;
  settings.RequiredByDefault := false;
  tmp := DelphiJSON<TTestSettings>.Deserialize(jsonData, settings);
end;
```

The class contains the following properties:
* RequireSerializableAttributeForNonRTLClasses
* DateTimeReturnUTC
* IgnoreNonNillable
* RequiredByDefault

### RequireSerializableAttributeForNonRTLClasses

Determines if the [DJSerializableAttribute] is needed as annotation for classes / records.
The default is true.
It is not recommended to set the value to false.
Most serializable RTL classes / records are not affected by this.

:warning: This should not be set to false, since it can cause classes to be (de)serialized that
are not intented for that.

### DateTimeReturnUTC

Determines if the date time (de)serialization assumes that the Delphi
value stored in a TDateTime object is considered to be UTC time.
The default is true.
More information can be found in the RTL documentation for [System.DateUtils.DateToISO8601](http://docwiki.embarcadero.com/Libraries/Sydney/en/System.DateUtils.DateToISO8601)

### IgnoreNonNillable

Makes the (de)serializer ignore all [DJNonNilableAttribute] annotations.
This can be used if values are allowed to be nil during serialization,
but not during deserialization.
It only affects fields annotated with [DJNonNilableAttribute].
The default is false.

### RequiredByDefault

If set to true, makes all fields required. If set to false all fields are optional.
This has only an effect during deserialization.
The default value if true.
This value is ignored if a field is annotated with the [DJRequiredAttribute].
A required field that is not present in a JSON object causes an
[EDJRequiredError] exception during deserialization.
If a field is not required, it has not to be present in the JSON object.
In this case the delphi field is not set to anything or a default value
if either the [DJDefaultValueAttribute] or the [DJDefaultValueCreatorAttribute] is present.


## Default Value
The concept of default values is implemented. For more info look at the interface documentation
and the test cases.

## Converters
The concept of converters are implemented. For more info look at the interface documentation
and the test cases.
