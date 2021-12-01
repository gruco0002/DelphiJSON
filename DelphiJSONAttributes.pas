///
/// DelphiJSON Library - Copyright (c) 2021 Corbinian Gruber
///
/// Version: 1.0.0
///
/// This library is licensed under the MIT License.
/// https://github.com/gruco0002/DelphiJSON
///

unit DelphiJSONAttributes;

interface

uses
  DelphiJSONTypes;

type

  /// <summary>
  /// Makes a field (de)serializable and specifies its JSON name.
  /// All fields that are not annotated with this attribute are ignored during
  /// the (de)serialization.
  /// The name has to be unique for an object.
  /// </summary>
  DJValueAttribute = class(TCustomAttribute)
  public
    Name: string;
    constructor Create(const Name: string);
  end;

  /// <summary>
  /// Makes a class or record (de)serializable.
  /// This attribute is needed to explicitly state that a class / record is serializable.
  /// </summary>
  DJSerializableAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Makes the annotated field non nillable.
  /// During (de)serialization a nil/null value for this field would cause an [EDJNilError].
  /// This behaviour can be overwritten by the [IgnoreNonNillable] property of the [TDJSettings].
  /// </summary>
  DJNonNilableAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Makes the annotated constructor the default constructor that is used for deserialization.
  /// The constructor must not have any arguments.
  /// If no constructor is annotated the Create constructor will be used (if it does not require any arguments)
  /// </summary>
  DJConstructorAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Internal interface used for default values.
  /// Each inherited class should implement a function with the name 'GetValue'
  /// that returns the respective default value.
  /// </summary>
  IDJDefaultValue = class(TCustomAttribute)
  protected
    function IsVariant: Boolean; virtual; abstract;
  end;

  /// <summary>
  /// Defines a default value for a field that is used during deserialization.
  /// The default value is used if the field is not defined in the given JSON object.
  /// This attribute only supports primitive values.
  /// This attribute has no effect if not used together with either the [DJDefaultOnNilAttribute] or the [DJRequiredAttribute].
  /// </summary>
  DJDefaultValueAttribute = class(IDJDefaultValue)
  private
    value: Variant;
  protected
    function IsVariant: Boolean; override;
  public
    function GetValue: Variant;
  public
    constructor Create(const value: string); overload;
    constructor Create(const value: integer); overload;
    constructor Create(const value: single); overload;
    constructor Create(const value: double); overload;
    constructor Create(const value: Boolean); overload;
    constructor Create(const value: Variant); overload;
  end;

  /// <summary>
  /// Defines an abstract generator for a default value for a field that is used
  /// during deserialization. To use the attribute, derive a custom non generic
  /// generator that implementes the [Generator] function and annotate the
  /// appropriate field.
  /// Be sure to use the correct type [T].
  /// The default value is used if the field is not defined in the given JSON object.
  /// The generator is called during the deserialization.
  /// This attribute has no effect if not used together with either the [DJDefaultOnNilAttribute] or the [DJRequiredAttribute].
  /// </summary>
  DJDefaultValueCreatorAttribute<T> = class(IDJDefaultValue)
  protected
    function IsVariant: Boolean; override;
  public
    function GetValue: T;
  public
    function Generator: T; virtual; abstract;
  end;

  /// <summary>
  /// Makes the field use the default value if it has the value nil / null during deserialization.
  /// This attribute has only an effect if used together with one of the default
  /// value attributes [DJDefaultValueCreatorAttribute] or [DJDefaultValueAttribute]
  /// </summary>
  DJDefaultOnNilAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Makes a field required if [required] is true and optional if [required] is false.
  /// The default value is true. This attribute only affects the deserialization.
  /// This overrides the settings given by the [DJSettings] object for the annotated field.
  /// If a required field is not specified in the JSON object an [EDJRequiredError] is thrown.
  /// Note that nil/null values for a field do not raise an exception, since the field is
  /// existing in the JSON object (See [DJNonNilableAttribute] for that case)
  /// </summary>
  DJRequiredAttribute = class(TCustomAttribute)
  public
    required: Boolean;
    constructor Create(const required: Boolean = true);
  end;

  /// <summary>
  /// Internal interface used for converters.
  /// </summary>
  IDJConverterInterface = class(TCustomAttribute)
  protected
    function Dummy: Boolean; virtual; abstract;
  end;

  /// <summary>
  /// Abstract converter attribute used to implement custom converters.
  /// Custom converters are implemented by the user by overriding the [ToJSON]
  /// and [FromJSON] functions.
  /// The custom converter is then used as an attribute to annotate the fields
  /// that should be (de)serialized using the converter.
  /// It is not required to implement both functions as the [ToJSON] function
  /// is only called during serialization and the [FromJSON] function is only
  /// called during deserialization.
  /// Converters are called instead of the normal (de)serialization for the
  /// given value.
  /// All other attributes of the annotated field are evaluated before the
  /// converter is called.
  /// </summary>
  DJConverterAttribute<T> = class(IDJConverterInterface)
  protected
    function Dummy: Boolean; override; // This allows for RTTI identification
  public
    procedure ToJSON(value: T; stream: TDJJsonStream); virtual; abstract;
    function FromJSON(stream: TDJJsonStream): T; virtual; abstract;
  end;

  /// <summary>
  /// Makes a class or record raise an error on deserialization if there are
  /// fields in the JSON data, that are not explicitly mapped to a field in the
  /// class or record (iff [noUnusedFields] is set to true).
  /// If the [noUnusedFields] is set to false, such additional JSON fields are
  /// ignored and no errors are raised
  /// Overrides the [AllowUnusedJSONFields] setting for the annotated class or
  /// record.
  /// </summary>
  DJNoUnusedJSONFieldsAttribute = class(TCustomAttribute)
  public
    noUnusedFields: Boolean;
    constructor Create(const noUnusedFields: Boolean = true);
  end;

implementation

type
  TTestRecord = record
    abc: integer;
  end;

  { DJValueAttribute }

constructor DJValueAttribute.Create(const Name: string);
begin
  self.Name := name;
end;

{ DJDefaultValueAttribute }

constructor DJDefaultValueAttribute.Create(const value: single);
begin
  self.value := Variant(value);
end;

constructor DJDefaultValueAttribute.Create(const value: integer);
begin
  self.value := Variant(value);
end;

constructor DJDefaultValueAttribute.Create(const value: string);
begin
  self.value := Variant(value);
end;

constructor DJDefaultValueAttribute.Create(const value: Variant);
begin
  self.value := value;
end;

constructor DJDefaultValueAttribute.Create(const value: Boolean);
begin
  self.value := Variant(value);
end;

constructor DJDefaultValueAttribute.Create(const value: double);
begin
  self.value := Variant(value);
end;

function DJDefaultValueAttribute.GetValue: Variant;
begin
  Result := self.value;
end;

function DJDefaultValueAttribute.IsVariant: Boolean;
begin
  Result := true;
end;

{ DJNoUnusedJSONFieldsAttribute }

constructor DJNoUnusedJSONFieldsAttribute.Create(const noUnusedFields: Boolean);
begin
  self.noUnusedFields := noUnusedFields;
end;

{ DJRequiredAttribute }

constructor DJRequiredAttribute.Create(const required: Boolean);
begin
  self.required := required;
end;

{ DJDefaultValueCreatorAttribute<T> }

function DJDefaultValueCreatorAttribute<T>.GetValue: T;
begin
  Result := self.Generator;
end;

function DJDefaultValueCreatorAttribute<T>.IsVariant: Boolean;
begin
  Result := False;
end;

{ DJConverterAttribute<T> }

function DJConverterAttribute<T>.Dummy: Boolean;
begin
  Result := true;
end;

end.
