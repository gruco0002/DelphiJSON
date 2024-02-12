///
/// DelphiJSON Library - Copyright (c) 2021 - 2023 Corbinian Gruber
///
/// Version: 2.0.0
///
/// This library is licensed under the MIT License.
/// https://github.com/gruco0002/DelphiJSON
///

unit DelphiJSON;

interface

uses
  System.Generics.Collections,
  System.JSON, System.JSON.Builders, System.JSON.Readers, System.JSON.Writers,
  System.RTTI,
  System.SysUtils;

type

{$REGION 'Forward Declarations'}
  TDJSettings = class;
  TDJJsonStream = class;
{$ENDREGION}

  /// <summary>
  /// Static class that has functions for (de)serializing.
  ///
  /// This class uses RTTI to (de)serialize!
  ///
  /// Note: always specify the correct type for [T]. Wrong types could lead to
  /// undefined behaviour.
  /// An instance of this class must not be created.
  /// </summary>
  DelphiJSON<T> = class

  public

    /// <summary>
    /// Deserializes the JSON string [data] into the specified object type.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the deserialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class function Deserialize(data: String; settings: TDJSettings = nil): T;

    /// <summary>
    /// Deserializes the JSON [stream] into the specified object type.
    /// The given [stream] is not freed by the function, but its contents are
    /// consumed by this function.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the deserialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class function DeserializeFromStream(stream: TDJJsonStream;
      settings: TDJSettings = nil): T;

    /// <summary>
    /// Deserializes the JSON value [data] into the specified object type.
    /// The given value [data] is not freed by the function.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the deserialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class function DeserializeJ(data: TJSONValue;
      settings: TDJSettings = nil): T;

    /// <summary>
    /// Serializes the given [data] into a JSON string.
    /// The [data] is not freed by the function.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the serialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class function Serialize(data: T; settings: TDJSettings = nil): string;

    /// <summary>
    /// Serializes the given [data] using the provided [stream].
    /// The [data] is not freed by the function.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the serialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// The [stream] object will be altered by the serializer. In case of error
    /// the [stream] could have undefined contents.
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class procedure SerializeIntoStream(data: T; stream: TDJJsonStream;
      settings: TDJSettings = nil);

    /// <summary>
    /// Serializes the given [data] into a JSON value.
    /// The [data] is not freed by the function.
    /// Optional settings can be given with the [settings] argument.
    /// If [settings] are given they are not freed by the function.
    /// If the serialization causes an error this function will throw this
    /// error after an internal cleanup to avoid memory leaks.
    /// The resources (JSON Values) are not managed by the serializer and belong
    /// to the caller of the function after it returns!
    /// Note: always specify the correct type for [T]. Wrong types could lead to
    /// undefined behaviour.
    /// </summary>
    class function SerializeJ(data: T; settings: TDJSettings = nil): TJSONValue;

  private
    constructor Create;

  end;

{$REGION 'Attributes'}

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
  public
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
  public
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
  public
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
    procedure ToJSON(value: T; stream: TDJJsonStream; settings: TDJSettings); virtual; abstract;
    function FromJSON(stream: TDJJsonStream; settings: TDJSettings): T; virtual; abstract;
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

  /// <summary>
  /// Defines a static/class function of a class or record to be used for
  /// deserialization instead of using the default deserializer.
  ///
  /// The function has to be a static class function with the following signature:
  /// class function Abc(stream: TDJJsonStream; settings: TDJSettings): TMyType; static;
  /// Where [Abc] can be an arbitrary function name and [TMyType] has to be
  /// the type of the corresponding record or class.
  ///
  /// If [doNotInherit] is set to true (the default value), class instances
  /// that inherit from the class that defines the function, will not cause
  /// the deserializer to call this function. For instance:
  /// DelphiJSON<TBase>.Deserialize(...) -> will call the function
  /// DelphiJSON<TInheritsBase>.Deserialize(...) -> will not call the function.
  /// The same holds for field definitions:
  /// abc: TBase; -> will call the function
  /// abc: TInheritsBase -> will not call the function
  /// If [doNotInherit] is set to false, all types that inherit from this
  /// class will use the annotated function for deserializing.
  DJFromJSONFunctionAttribute = class(TCustomAttribute)
  public
    doNotInherit: Boolean;
    constructor Create(const doNotInherit: Boolean = true);
  end;

  /// <summary>
  /// Defines a regular function of a class or record to be used for
  /// serialization instead of using the default serializer.
  ///
  /// The function has to have the following signature:
  /// procedure TMyType.Abc(stream: TDJJsonStream; settings: TDJSettings);
  /// Where [Abc] can be an arbitrary function name and [TMyType] has to be
  /// the type of the corresponding record or class.
  DJToJSONFunctionAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// If applied to a field the [DJNullIfEmptyAttribute] is active during
  /// serialization and causes an empty [string] to be represented by the
  /// JSON null literal instead of an empty JSON string literal.
  /// </summary>
  DJNullIfEmptyStringAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// If applied to a field the [DJIgnoreFieldIfNil] is active during
  /// serialization and causes a field to not be serialized if its value
  /// is nil.
  /// </summary>
  DJIgnoreFieldIfNil = class(TCustomAttribute)
  end;

{$ENDREGION}

{$REGION 'Types (Streams, Settings, Errors)'}

  /// <summary>
  /// [TDJJsonStream] is an abstract class that provides the (de)serialization
  /// of DelphiJSON with an api for reading and writing JSON data. This allows
  /// using different JSON libraries and data structures like TJSONValue or
  /// LJsonTextReader from the RTL for the (de)serialization process.
  ///
  /// A default implementation for TJSONValue is provided further down.
  ///
  /// About the structure:
  /// A new json stream always starts with no active value (nil).
  ///
  /// In case of reading the read-pointer would point to the given json value.
  /// If the current read pointer points towards an object or array the reader
  /// can step into it and the active value becomes the respective object or
  /// array. The read pointer points then to the first property / value of the
  /// object / array that became active. The read pointer can be nil / invalid
  /// if an object / array has no properties / elements. The ReadIsDone then
  /// yields true. It also returns true if all properties or elements are
  /// "consumed" by the reader. By calling ReadNext the read pointer goes to
  /// the next property / element.
  /// The active values are saved in a stack like manner. By calling
  /// ReadStepOut the active value changes to the previous active value of the
  /// stack. This also causes the ReadNext behaviour to be executed on the
  /// previous active value. This means that you can not step back into the
  /// object or array after you stepped out of it.
  ///
  /// </summary>
  TDJJsonStream = class
  public type
    TDJJsonStreamTypes = (djstObject, djstArray, djstNull, djstBoolean,
      djstNumberInt, djstNumberFloat, djstString);
  public
    // reading

    /// <summary>
    /// Reads the next value of the current array or object
    /// </summary>
    procedure ReadNext; virtual; abstract;

    /// <summary>
    /// States if there are no more values left to read in the current array or object.
    /// This will only be true if [ReadNext] was unsuccessful
    /// </summary>
    function ReadIsDone: Boolean; virtual; abstract;

    /// <summary>
    /// Returns the type of the current active value
    /// </summary>
    function ReadGetType: TDJJsonStreamTypes; virtual; abstract;

    /// <summary>
    /// Steps into the current active value if it is an array or object
    /// </summary>
    procedure ReadStepInto; virtual; abstract;

    /// <summary>
    /// Steps out of the current array or object if inside one.
    /// </summary>
    procedure ReadStepOut; virtual; abstract;

    /// <summary>
    /// States if [ReadStepOut] is possible.
    /// </summary>
    function ReadIsRoot: Boolean; virtual; abstract;

    /// <summary>
    /// Returns the property name of the current active property.
    /// The string is empty if there is no property name.
    /// </summary>
    function ReadPropertyName: String; virtual; abstract;

    /// <summary>
    /// States if the current active value is null.
    /// </summary>
    function ReadValueIsNull: Boolean; virtual; abstract;

    /// <summary>
    /// Returns the current active value as boolean if it is a boolean.
    /// </summary>
    function ReadValueBoolean: Boolean; virtual; abstract;

    /// <summary>
    /// Returns the current active value as string if it is a string.
    /// </summary>
    function ReadValueString: string; virtual; abstract;

    /// <summary>
    /// Returns the current active value as integer if it is an integer.
    /// </summary>
    function ReadValueInteger: Int64; virtual; abstract;

    /// <summary>
    /// Returns the current active value as float if it is a float.
    /// </summary>
    function ReadValueFloat: double; virtual; abstract;

  public
    // writing

    /// <summary>
    /// Sets the property name for the next value. The property name specified
    /// here will be used only if no (empty) property name is given in the
    /// WriteValue... or WriteBegin... call. Otherwise it will be discarded.
    ///
    /// If the current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteSetNextPropertyName(const propertyName: string);
      virtual; abstract;

    /// <summary>
    /// Begins a new object.
    /// If propertyName is not empty the object will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteBeginObject(const propertyName: string = '');
      virtual; abstract;

    /// <summary>
    /// Ends the current object. If no object is active this causes an
    /// exception.
    /// </summary>
    procedure WriteEndObject; virtual; abstract;

    /// <summary>
    /// Begins a new array.
    /// If propertyName is not empty the array will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteBeginArray(const propertyName: string = '');
      virtual; abstract;

    /// <summary>
    /// Ends the current array. If no array is active this causes an exception.
    /// </summary>
    procedure WriteEndArray; virtual; abstract;

    /// <summary>
    /// Writes the value nil.
    /// If propertyName is not empty the nil-value will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteValueNull(const propertyName: string = ''); virtual;
      abstract;

    /// <summary>
    /// Writes a boolean value.
    /// If propertyName is not empty the boolean will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteValueBoolean(value: Boolean;
      const propertyName: string = ''); virtual; abstract;

    /// <summary>
    /// Writes a string value.
    /// If propertyName is not empty the string will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteValueString(const value: string;
      const propertyName: string = ''); virtual; abstract;

    /// <summary>
    /// Writes an integer value.
    /// If propertyName is not empty the integer will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteValueInteger(const value: Int64;
      const propertyName: string = ''); virtual; abstract;

    /// <summary>
    /// Writes a float value.
    /// If propertyName is not empty the float will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteValueFloat(const value: double;
      const propertyName: string = ''); virtual; abstract;

  end;

  /// <summary>
  /// Defines settings for the (de)serialization.
  /// </summary>
  TDJSettings = class
  public

    /// <summary>
    /// Determines if the [DJSerializableAttribute] is needed as annotation for classes / records.
    /// The default is true.
    /// It is not recommended to set the value to false.
    /// Most serializable RTL classes / records are not affected by this.
    /// </summary>
    RequireSerializableAttributeForNonRTLClasses: Boolean;

    /// <summary>
    /// Determines if the date time (de)serialization assumes that the Delphi
    /// value stored in a TDateTime object is considered to be UTC time.
    /// The default is true.
    /// More information can be found in the RTL documentation for [System.DateUtils.DateToISO8601]
    /// </summary>
    DateTimeReturnUTC: Boolean;

    /// <summary>
    /// Makes the (de)serializer ignore all [DJNonNilableAttribute] annotations.
    /// This can be used if values are allowed to be nil during serialization,
    /// but not during deserialization.
    /// It only affects fields annotated with [DJNonNilableAttribute].
    /// The default is false.
    /// </summary>
    IgnoreNonNillable: Boolean;

    /// <summary>
    /// If set to true, makes all fields required. If set to false all fields are optional.
    /// This has only an effect during deserialization.
    /// The default value if true.
    /// This value is ignored if a field is annotated with the [DJRequiredAttribute].
    /// A required field that is not present in a JSON object causes an
    /// [EDJRequiredError] exception during deserialization.
    /// If a field is not required, it has not to be present in the JSON object.
    /// In this case the delphi field is not set to anything or a default value
    /// if either the [DJDefaultValueAttribute] or the [DJDefaultValueCreatorAttribute] is present.
    /// </summary>
    RequiredByDefault: Boolean;

    /// <summary>
    /// If set to true, the (de)serializer assumes that TDictionary's that have
    /// string set as their key type are represented by JSON objects and
    /// (de)serializes them respectively. If set to false, those TDictionary's
    /// will be (de)serialized like other dictionaries (to/from a JSON array of
    /// key-value objects).
    /// The default value is true.
    /// </summary>
    TreatStringDictionaryAsObject: Boolean;

    /// <summary>
    /// If set to true, the deserializer ignores fields in the JSON data, that
    /// are not used for deserialization (that have no counterpart in the delphi
    /// data representation). If set to false the deserialization raises an
    /// exception upon encountering unused fields.
    /// The default value is true.
    /// This value is ignored for a class or record if it is annotated with the
    /// [DJNoUnusedJSONFieldsAttribute].
    /// </summary>
    AllowUnusedJSONFields: Boolean;

    /// <summary>
    /// A map of custom properties that can be passed into the (de)serialization
    /// process.
    /// [CustomProperties] is created, owned and freed by an instance of
    /// [TDJSettings].
    /// </summary>
    CustomProperties: TDictionary<String, String>;

    /// <summary>
    /// Creates the default settings for (de)serialization.
    /// </summary>
    constructor Default;

    destructor Destroy; override;

  end;

  /// <summary>
  /// Describes an error that happened during deserialization.
  /// </summary>
  EDJError = class(exception)
  public
    path: TArray<String>;
    errorMessage: String;
    constructor Create(errorMessage: String; path: TArray<String>);
    destructor Destroy; override;
    function FullPath: string;

    class function PathToString(path: TArray<String>): String;
  end;

  /// <summary>
  /// This error is raised if an required field is not found in the JSON object.
  /// </summary>
  EDJRequiredError = class(EDJError)
  public
  end;

  /// <summary>
  /// This error is raised if a field is nil/null although it is annotated with
  /// the [DJNonNilableAttribute].
  /// </summary>
  EDJNilError = class(EDJError)
  public
  end;

  /// <summary>
  /// This error is raised if a fixed sized array is being deserialized and the
  /// size of the array in the JSON data does not match the delphi fixed array
  /// size.
  /// </summary>
  EDJWrongArraySizeError = class(EDJError)
  public
  end;

  /// <summary>
  /// This error is raised if a reference cycle during serialization is
  /// detected.
  /// A reference cycle can occur if fields that are serialized point towards
  /// objects that have already been serialized or are in the process of being
  /// serialized.
  /// </summary>
  EDJCycleError = class(EDJError)
  public
  end;

  /// <summary>
  /// This error is raised if unused fields are discovered in the JSON data
  /// during the deserialization and such fields are not allowed.
  /// See the [DJNoUnusedJSONFieldsAttribute] or the [AllowUnusedJSONFields]
  /// property of the [TDJSettings] for more information.
  /// </summary>
  EDJUnusedFieldsError = class(EDJError)
  public
  end;

  /// <summary>
  /// This error is raised if a wrong format of the JSON data is provided during
  /// deserialization.
  /// E.g.: A DateTime string should be deserialized but does not meet the
  /// requirement of the ISO 8601 format.
  /// </summary>
  EDJFormatError = class(EDJError)
  public
  end;

  // Implementations of TDJJsonStream following

  /// <summary>
  /// Implements helper methods for the TDJJsonStream instances.
  /// </summary>
  TDJJsonStreamHelper = class helper for TDJJsonStream
  public
    // helpers for standard conversion from/into TJSONValue  /// <summary>
    /// Reads the current active value as TJSONValue and returns it.
    /// </summary>
    function ReadAsTJsonValue: TJSONValue;
    /// <summary>
    /// Writes the json value.
    /// If propertyName is not empty the json value will be added
    /// as field with the name propertyName to the current value. If the
    /// current value is not an object this will cause an exception.
    /// </summary>
    procedure WriteTJsonValue(value: TJSONValue;
      const propertyName: string = '');
  end;

  /// <summary>
  /// Implementation of the TDJJsonStream for TJsonValue based input data.
  /// </summary>
  TDJTJsonValueStream = class(TDJJsonStream)
  public
    procedure ReadNext; override;
    function ReadIsDone: Boolean; override;
    function ReadGetType: TDJJsonStream.TDJJsonStreamTypes; override;
    procedure ReadStepInto; override;
    procedure ReadStepOut; override;
    function ReadIsRoot: Boolean; override;
    function ReadPropertyName: String; override;
    function ReadValueIsNull: Boolean; override;
    function ReadValueBoolean: Boolean; override;
    function ReadValueString: string; override;
    function ReadValueInteger: Int64; override;
    function ReadValueFloat: double; override;

  public
    procedure WriteSetNextPropertyName(const propertyName: string); override;
    procedure WriteBeginObject(const propertyName: string = ''); override;
    procedure WriteEndObject; override;
    procedure WriteBeginArray(const propertyName: string = ''); override;
    procedure WriteEndArray; override;
    procedure WriteValueNull(const propertyName: string = ''); override;
    procedure WriteValueBoolean(value: Boolean;
      const propertyName: string = ''); override;
    procedure WriteValueString(const value: string;
      const propertyName: string = ''); override;
    procedure WriteValueInteger(const value: Int64;
      const propertyName: string = ''); override;
    procedure WriteValueFloat(const value: double;
      const propertyName: string = ''); override;

  public
    constructor CreateReader(value: TJSONValue;
      readRootValueOwnedByStream: Boolean = false);
    constructor CreateWriter;

    destructor Destroy; override;

    /// <summary>
    /// Returns the written value. Note that the written value is still hold by
    /// the stream and freed when the stream is freed.
    /// </summary>
    function ViewWrittenValue: TJSONValue;

    /// <summary>
    /// Returns the written value and removes it from the stream. The stream is
    /// afterwards in an invalid state and can only be freed. The returned value
    /// will not be freed by the stream or when the stream gets freed.
    /// </summary>
    function ExtractWrittenValue: TJSONValue;

  private
    isInReadMode: Boolean;

    // read related data structures
    readActiveValue: TStack<TJSONValue>;
    readPointer: TStack<integer>;
    readRootValue: TJSONValue;
    readRootValueOwnedByStream: Boolean;

    // write related data structures
    writeNextPropertyName: String;
    writeActiveValue: TStack<TJSONValue>;
    writeRootValue: TJSONValue;

    function ReadGetPointedTJSONValue: TJSONValue;
    function ReadGetPointedPropertyName: String;
    procedure WriteJsonValue(value: TJSONValue; propertyName: string = '');
    function WriteGetFinalPropertyName(propertyName: string): string;
    function WriteGetActiveValue: TJSONValue;

  private
    // utilities
    class function GetTypeOfValue(value: TJSONValue)
      : TDJJsonStream.TDJJsonStreamTypes;

  end;

  /// <summary>
  /// Implementation of the TDJJsonStream for TJSONReader / TJSONWriter based
  /// input data.
  /// </summary>
  TDJTJsonRWStream = class(TDJJsonStream)
  public
    procedure ReadNext; override;
    function ReadIsDone: Boolean; override;
    function ReadGetType: TDJJsonStream.TDJJsonStreamTypes; override;
    procedure ReadStepInto; override;
    procedure ReadStepOut; override;
    function ReadIsRoot: Boolean; override;
    function ReadPropertyName: String; override;
    function ReadValueIsNull: Boolean; override;
    function ReadValueBoolean: Boolean; override;
    function ReadValueString: string; override;
    function ReadValueInteger: Int64; override;
    function ReadValueFloat: double; override;
  public
    procedure WriteSetNextPropertyName(const propertyName: string); override;
    procedure WriteBeginObject(const propertyName: string = ''); override;
    procedure WriteEndObject; override;
    procedure WriteBeginArray(const propertyName: string = ''); override;
    procedure WriteEndArray; override;
    procedure WriteValueNull(const propertyName: string = ''); override;
    procedure WriteValueBoolean(value: Boolean;
      const propertyName: string = ''); override;
    procedure WriteValueString(const value: string;
      const propertyName: string = ''); override;
    procedure WriteValueInteger(const value: Int64;
      const propertyName: string = ''); override;
    procedure WriteValueFloat(const value: double;
      const propertyName: string = ''); override;
  public
    constructor CreateReader(reader: TJSONReader;
      readerOwnedByThisObject: Boolean = false);
    constructor CreateWriter(writer: TJSONWriter;
      writerOwnedByThisObject: Boolean = false);
    destructor Destroy; override;
  private
    isInReadMode: Boolean;
    // read related data structures
    readReader: TJSONReader;
    readReaderOwnedByThisObject: Boolean;
    readIterator: TJSONIterator;
    readLastPropertyName: string;
    readIsDoneFlag: Boolean;
    // write related data structures
    writeWriter: TJSONWriter;
    writeWriterOwnedByThisObject: Boolean;
    writeNextPropertyName: String;
  private
    function WriteGetFinalPropertyName(propertyName: string): string;
    procedure WriteWriteFinalPropertyName(propertyName: string);
  end;
{$ENDREGION}

{$REGION 'Internal functions and classes'}


type
  /// <summary>
  /// (De)Serialization context.
  /// This class has to be exposed to the interface to be used inside the generic DelphiJSON<T>.
  /// </summary>
  TSerContext = class
  private
    path: TStack<string>;

    // keeps track of heap allocated objects in order to free them, if an error happens and no value can be returned
    // this is implemented to avoid memory leaks through invalid json or parameters / other issues
    heapAllocatedObjects: TDictionary<TObject, Boolean>;

    // used to detect cycles during serialization
    objectTracker: TDictionary<TObject, Boolean>;

    procedure NilAllReferencesRecursive(value: TValue);

  public
    RTTI: TRttiContext;
    settings: TDJSettings;

    stream: TDJJsonStream;

    constructor Create;
    destructor Destroy; override;

    function GetPath: TArray<string>;
    procedure PushPath(val: string); overload;
    procedure PushPath(index: integer); overload;
    procedure PopPath;

    procedure AddHeapObject(obj: TObject);
    procedure RemoveHeapObject(obj: TObject);
    procedure FreeAllHeapObjects;

    procedure Track(obj: TObject);
    function IsTracked(obj: TObject): Boolean;

  end;

  TDerContext = TSerContext;

  /// <summary>
  /// Internal serialization function.
  /// This class has to be exposed to the interface to be used inside the generic DelphiJSON<T>.
  /// </summary>
procedure SerializeInternal(value: TValue; context: TSerContext; nullIfEmptyString: Boolean = false);

/// <summary>
/// Internal deserialization function.
/// This class has to be exposed to the interface to be used inside the generic DelphiJSON<T>.
/// </summary>
function DeserializeInternal(dataType: TRttiType; context: TDerContext): TValue;

{$ENDREGION}

implementation

uses
  System.TypInfo, System.DateUtils, System.Variants;

var
  unitRttiContextInstance: TRttiContext;

{$REGION 'RTTI (De)Serialization Implementation'}


procedure SerArray(value: TValue; context: TSerContext);
var
  size: integer;
  i: integer;
begin
  context.stream.WriteBeginArray();
  size := value.GetArrayLength;
  for i := 0 to size - 1 do
  begin
    context.PushPath(i.ToString);
    SerializeInternal(value.GetArrayElement(i), context);
    context.PopPath;
  end;

  context.stream.WriteEndArray;
end;

procedure SerFloat(value: TValue; context: TSerContext);
begin
  context.stream.WriteValueFloat(value.AsType<single>());
end;

procedure SerInt64(value: TValue; context: TSerContext);
begin
  context.stream.WriteValueInteger(value.AsInt64);
end;

procedure SerInt(value: TValue; context: TSerContext);
begin
  context.stream.WriteValueInteger(value.AsInteger);
end;

procedure SerString(value: TValue; context: TSerContext; nullIfEmptyString: Boolean);
begin
  if nullIfEmptyString then
  begin
    if value.AsString.IsEmpty then
    begin
      context.stream.WriteValueNull;
      exit;
    end;
  end;
  context.stream.WriteValueString(value.AsString);
end;

procedure SerTEnumerable(data: TObject; dataType: TRttiType;
  context: TSerContext);
var
  getEnumerator: TRttiMethod;
  enumerator: TValue;
  moveNext: TRttiMethod;
  currentProperty: TRttiProperty;
  currentValue: TValue;

  moveNextValue: TValue;
  moveNextResult: Boolean;
  i: integer;
begin
  // idea: fetch enumerator with rtti, enumerate using movenext, adding objects
  // to the array

  getEnumerator := dataType.GetMethod('GetEnumerator');
  enumerator := getEnumerator.Invoke(data, []);

  moveNext := getEnumerator.ReturnType.GetMethod('MoveNext');
  currentProperty := getEnumerator.ReturnType.GetProperty('Current');

  context.stream.WriteBeginArray();

  // inital move
  moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
  moveNextResult := moveNextValue.AsBoolean;

  i := 0;
  while moveNextResult do
  begin
    // retrieve current object
    currentValue := currentProperty.GetValue(enumerator.AsObject);

    // serialize it and add it to the result
    context.PushPath(i.ToString);
    SerializeInternal(currentValue, context);
    context.PopPath;

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
    moveNextResult := moveNextValue.AsBoolean;
    Inc(i);
  end;

  enumerator.AsObject.Free;

  context.stream.WriteEndArray;
end;

procedure SerTDictionaryStringKey(data: TObject; dataType: TRttiType;
  context: TSerContext);
var
  getEnumerator: TRttiMethod;
  enumerator: TValue;
  moveNext: TRttiMethod;
  currentProperty: TRttiProperty;
  currentPairValue: TValue;

  keyField: TRttiField;
  valueField: TRttiField;
  keyValue: TValue;
  valueValue: TValue;
  keyString: string;

  moveNextValue: TValue;
  moveNextResult: Boolean;
begin
  // idea: the string keys are used as object field names and the values form
  // the respective field value

  getEnumerator := dataType.GetMethod('GetEnumerator');
  enumerator := getEnumerator.Invoke(data, []);

  moveNext := getEnumerator.ReturnType.GetMethod('MoveNext');
  currentProperty := getEnumerator.ReturnType.GetProperty('Current');

  keyField := currentProperty.PropertyType.GetField('Key');
  valueField := currentProperty.PropertyType.GetField('Value');

  context.stream.WriteBeginObject();

  // inital move
  moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
  moveNextResult := moveNextValue.AsBoolean;

  while moveNextResult do
  begin
    // retrieve current pair
    currentPairValue := currentProperty.GetValue(enumerator.AsObject);

    keyValue := keyField.GetValue(currentPairValue.GetReferenceToRawData);
    valueValue := valueField.GetValue(currentPairValue.GetReferenceToRawData);

    keyString := keyValue.AsString;

    context.PushPath(keyString);
    context.stream.WriteSetNextPropertyName(keyString);
    SerializeInternal(valueValue, context);
    context.PopPath;

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
    moveNextResult := moveNextValue.AsBoolean;
  end;

  enumerator.AsObject.Free;

  context.stream.WriteEndObject;

end;

procedure SerTPair(data: TValue; dataType: TRttiType; context: TSerContext);
var
  keyField: TRttiField;
  valueField: TRttiField;
  keyValue: TValue;
  valueValue: TValue;

begin
  keyField := dataType.GetField('Key');
  valueField := dataType.GetField('Value');

  keyValue := keyField.GetValue(data.GetReferenceToRawData);
  valueValue := valueField.GetValue(data.GetReferenceToRawData);

  context.stream.WriteBeginObject();

  context.PushPath('key');
  context.stream.WriteSetNextPropertyName('key');
  SerializeInternal(keyValue, context);
  context.PopPath;
  context.PushPath('value');
  context.stream.WriteSetNextPropertyName('value');
  SerializeInternal(valueValue, context);
  context.PopPath;

  context.stream.WriteEndObject;
end;

procedure SerTDateTime(data: TValue; dataType: TRttiType; context: TSerContext);
var
  dt: TDateTime;
  str: string;
begin
  dt := data.AsType<TDateTime>();
  str := DateToISO8601(dt, context.settings.DateTimeReturnUTC);
  context.stream.WriteValueString(str);
end;

procedure SerTDate(data: TValue; dataType: TRttiType; context: TSerContext);
const
  format = 'yyyy-mm-dd';
var
  dt: TDate;
  str: string;
begin
  dt := data.AsType<TDate>();
  DateTimeToString(str, format, dt);
  context.stream.WriteValueString(str);
end;

procedure SerTTime(data: TValue; dataType: TRttiType; context: TSerContext);
const
  format = 'hh:nn:ss.z';
var
  dt: TTime;
  str: string;
begin
  dt := data.AsType<TTime>();
  DateTimeToString(str, format, dt);
  context.stream.WriteValueString(str);
end;

procedure SerTJSONValue(data: TValue; dataType: TRttiType;
  context: TSerContext);
var
  original: TJSONValue;
begin
  original := data.AsType<TJSONValue>();
  context.stream.WriteTJsonValue(original);
end;

function SerHandledSpecialCase(data: TValue; dataType: TRttiType;
  context: TSerContext): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.ToLower = 'tdatetime' then
    begin
      Result := true;
      SerTDateTime(data, dataType, context);
      exit;
    end;

    if tmp.Name.ToLower = 'tdate' then
    begin
      Result := true;
      SerTDate(data, dataType, context);
      exit;
    end;

    if tmp.Name.ToLower = 'ttime' then
    begin
      Result := true;
      SerTTime(data, dataType, context);
      exit;
    end;

    if tmp.Name.ToLower = 'tjsonvalue' then
    begin
      Result := true;
      SerTJSONValue(data, dataType, context);
      exit;
    end;

    if context.settings.TreatStringDictionaryAsObject and
      (tmp.Name.ToLower.StartsWith('tdictionary<system.string,', true) or
      tmp.Name.ToLower.StartsWith('tdictionary<string,', true)) then
    begin
      Result := true;
      SerTDictionaryStringKey(data.AsObject, dataType, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tpair<', true) then
    begin
      Result := true;
      SerTPair(data, dataType, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tenumerable<', true) then
    begin
      Result := true;
      SerTEnumerable(data.AsObject, dataType, context);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := false;
end;

procedure SerUsingConverter(value: TValue; dataType: TRttiType;
  converter: IDJConverterInterface; context: TSerContext);
var
  converterType: TRttiType;
  streamType: TRttiType;
  methods: TArray<TRttiMethod>;
  method: TRttiMethod;
  parameters: TArray<TRttiParameter>;
  typeParameter: TRttiParameter;
  streamParameter: TRttiParameter;
begin
  // The following function needs to be implemented in the converter
  // procedure ToJSON(value: T; stream: TDJJsonStream); virtual; abstract;

  converterType := context.RTTI.GetType(converter.ClassType);
  streamType := context.RTTI.GetType(System.TypeInfo(TDJJsonStream));

  // get "ToJSON" method from converter
  methods := converterType.GetMethods('ToJSON');
  if Length(methods) = 0 then
  begin
    raise EDJError.Create('Could not find method "ToJSON" on converter!',
      context.GetPath);
  end;
  method := methods[Low(methods)];

  // get parameters types and verify their correctness
  parameters := method.GetParameters;
  if Length(parameters) <> 3 then
  begin
    raise EDJError.Create
      ('Invalid amount of parameters for method "ToJSON" on converter!',
      context.GetPath);
  end;
  typeParameter := parameters[Low(parameters)];
  streamParameter := parameters[Low(parameters) + 1];

  if typeParameter.ParamType <> dataType then
  begin
    raise EDJError.Create
      ('Type of data field does not match the fields type for method "ToJSON" on converter!',
      context.GetPath);
  end;

  if streamParameter.ParamType <> streamType then
  begin
    raise EDJError.Create
      ('Type of stream field does not match TDJJsonStream for method "ToJSON" on converter!',
      context.GetPath);
  end;

  // TODO: check type of settings parameter

  // invoke the method after everything else seems fine
  method.Invoke(converter, [value, TValue.From<TDJJsonStream>(context.stream), TValue.From<TDJSettings>(context.settings)]);

end;

procedure SerObject(value: TValue; context: TSerContext; isRecord: Boolean; isInterface: Boolean);
type
  TJsonFieldProperties = record
    foundDJValueAttribute: Boolean;
    nillable: Boolean;
    converter: IDJConverterInterface;
    nullIfEmptyString: Boolean;
    jsonFieldName: string;
    ignoreFieldIfNil: Boolean;
    fieldValue: TValue;
  end;
var
  objectType: TRttiType;
  objectField: TRttiField;
  objectProperty: TRttiProperty;
  objectMethod: TRttiMethod;

  jsonFieldProperties: TJsonFieldProperties;

  procedure SetJsonFieldPropertiesToDefaults;
  begin
    jsonFieldProperties.foundDJValueAttribute := false;
    jsonFieldProperties.nillable := true;
    jsonFieldProperties.converter := nil;
    jsonFieldProperties.nullIfEmptyString := false;
    jsonFieldProperties.jsonFieldName := '';
    jsonFieldProperties.fieldValue := nil;
    jsonFieldProperties.ignoreFieldIfNil := false;
  end;

  procedure ObtainJsonFieldPropertiesFromAttributes(obj: TRttiObject);
  var
    attribute: TCustomAttribute;
  begin
    // check for the attributes
    for attribute in obj.GetAttributes() do
    begin
      if attribute is DJValueAttribute then
      begin
        // found the value attribute (this needs to be serialized)
        jsonFieldProperties.foundDJValueAttribute := true;
        jsonFieldProperties.jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
      end
      else if attribute is DJNonNilableAttribute then
      begin
        // nil is not allowed
        jsonFieldProperties.nillable := false;
      end
      else if attribute is IDJConverterInterface then
      begin
        jsonFieldProperties.converter := attribute as IDJConverterInterface;
      end
      else if attribute is DJNullIfEmptyStringAttribute then
      begin
        jsonFieldProperties.nullIfEmptyString := true;
      end
      else if attribute is DJIgnoreFieldIfNil then
      begin
        jsonFieldProperties.ignoreFieldIfNil := true;
      end;
    end;

    // check if nillable is allowed
    if context.settings.IgnoreNonNillable then
    begin
      jsonFieldProperties.nillable := true;
    end;

    if jsonFieldProperties.foundDJValueAttribute then
    begin
      // check if the field name is valid
      if string.IsNullOrWhiteSpace(jsonFieldProperties.jsonFieldName) then
      begin
        raise EDJError.Create('Invalid JSON field name: is null or whitespace. ',
          context.GetPath);
      end;
    end;
  end;

  procedure SerializeFieldUsingProvidedProperties(fieldType: TRttiType);
  begin
    // serialize using properties
    context.PushPath(jsonFieldProperties.jsonFieldName);

    // check if field is nil
    if jsonFieldProperties.fieldValue.IsObject then
    begin
      if (not jsonFieldProperties.nillable) and (jsonFieldProperties.fieldValue.AsObject = nil) then
      begin
        raise EDJNilError.Create('Field value must not be nil, but was nil. ',
          context.GetPath);
      end
      else if jsonFieldProperties.ignoreFieldIfNil and (jsonFieldProperties.fieldValue.AsObject = nil) then
      begin
        // the field is nil and is marked to be ignored in this case
        exit;
      end;
    end;

    // serialize
    context.stream.WriteSetNextPropertyName(jsonFieldProperties.jsonFieldName);
    if jsonFieldProperties.converter <> nil then
    begin
      // use the converter
      SerUsingConverter(jsonFieldProperties.fieldValue, fieldType, jsonFieldProperties.converter, context);
    end
    else
    begin
      if jsonFieldProperties.fieldValue.IsObject and (jsonFieldProperties.fieldValue.AsObject = nil) and (not jsonFieldProperties.fieldValue.IsArray) then
      begin
        // field is nil and allowed to be nil, hence return a json null
        context.stream.WriteValueNull();
      end
      else
      begin
        // use the default serialization
        SerializeInternal(jsonFieldProperties.fieldValue, context, jsonFieldProperties.nullIfEmptyString);
      end;
    end;
    context.PopPath;
  end;

  procedure EnsureDJSerializableAttributePresent;
  var
    found: Boolean;
    attribute: TCustomAttribute;
    BaseType: TRttiType;
  begin
    found := false;
    while not found do
    begin
      // check for the presence of the DJSerializableAttribute
      for attribute in objectType.GetAttributes() do
      begin
        if attribute is DJSerializableAttribute then
        begin
          found := true;
          break;
        end;
      end;
      if found then
      begin
        break;
      end;

      // check the base type of this object if available, this means that only the base type fields are serialized
      BaseType := objectType.BaseType;
      if BaseType = nil then
      begin
        break;
      end;
      if objectType.Equals(BaseType) then
      begin
        break;
      end;
      objectType := BaseType;
    end;

    // if no DJSerializableAttribute is found raise an error
    if not found then
    begin
      raise EDJError.Create
        ('Given object type is missing the JSONSerializable attribute.',
        context.GetPath);
    end;
  end;

  function CheckIfToJsonAttributeIsPresent: Boolean;
  var
    methods: TArray<TRttiMethod>;
    method: TRttiMethod;
    attribute: TCustomAttribute;
  begin
    Result := false;
    methods := objectType.GetMethods;
    for method in methods do
    begin
      for attribute in method.GetAttributes do
      begin
        if attribute is DJToJSONFunctionAttribute then
        begin
          // serialize the object using this function
          Result := true;
          method.Invoke(value, [context.stream, context.settings]);
          exit;
        end;
      end;
    end;
  end;

begin
  // handle a "standard" object and serialize it

  // obtain the objects type
  objectType := context.RTTI.GetType(value.TypeInfo);

  // check for DJSerializable requirement
  if context.settings.RequireSerializableAttributeForNonRTLClasses then
  begin
    // Ensure the object has the serializable attribute.
    EnsureDJSerializableAttributePresent;
  end;

  // check if this object has a DJToJSONFunctionAttribute
  if CheckIfToJsonAttributeIsPresent then
  begin
    exit;
  end;

  // Init the result object
  context.stream.WriteBeginObject();

  // serialize object fields that are annotated
  for objectField in objectType.GetFields do
  begin
    // default values for properties
    SetJsonFieldPropertiesToDefaults;

    // obtain all properties
    ObtainJsonFieldPropertiesFromAttributes(objectField);

    if not jsonFieldProperties.foundDJValueAttribute then
    begin
      // skip this field since it is not opted-in for serialization
      continue;
    end;

    // obtain value of the field
    if isRecord then
    begin
      jsonFieldProperties.fieldValue := objectField.GetValue(value.GetReferenceToRawData);
    end
    else
    begin
      // the object is a class, since interfaces do not have fields
      jsonFieldProperties.fieldValue := objectField.GetValue(value.AsObject);
    end;

    // serialize
    SerializeFieldUsingProvidedProperties(objectField.fieldType);
  end;

  // serialize object properties that are annotated
  for objectProperty in objectType.GetProperties do
  begin
    // FIXME: There are no properties availabe using RTTI for interfaces, despite the
    // documentation at https://docwiki.embarcadero.com/Libraries/Sydney/en/System.Rtti.TRttiType.GetProperties
    // claiming that there should be!

    if not objectProperty.IsReadable then
    begin
      // we can only process readable properties
      continue;
    end;

    // default values for properties
    SetJsonFieldPropertiesToDefaults;

    // obtain all properties
    ObtainJsonFieldPropertiesFromAttributes(objectProperty);

    if not jsonFieldProperties.foundDJValueAttribute then
    begin
      // skip this property since it is not opted-in for serialization
      continue;
    end;

    // obtain value of the property
    if isRecord then
    begin
      jsonFieldProperties.fieldValue := objectProperty.GetValue(value.GetReferenceToRawData);
    end
    else if isInterface then
    begin
      jsonFieldProperties.fieldValue := objectProperty.GetValue(value.AsInterface);
    end
    else
    begin
      jsonFieldProperties.fieldValue := objectProperty.GetValue(value.AsObject);
    end;

    // serialize
    SerializeFieldUsingProvidedProperties(objectProperty.PropertyType);
  end;

  // serialize getter methods if annotated
  for objectMethod in objectType.GetMethods do
  begin
    if objectMethod.MethodKind <> TMethodKind.mkFunction then
    begin
      // only support functions
      continue;
    end;

    if Length(objectMethod.GetParameters) <> 0 then
    begin
      // only support getter methods
      continue;
    end;

    // default values for properties
    SetJsonFieldPropertiesToDefaults;

    // obtain all properties
    ObtainJsonFieldPropertiesFromAttributes(objectMethod);

    if not jsonFieldProperties.foundDJValueAttribute then
    begin
      // skip this property since it is not opted-in for serialization
      continue;
    end;

    // obtain value of the property
    if isRecord then
    begin
      jsonFieldProperties.fieldValue := objectMethod.Invoke(value.GetReferenceToRawData, []);
    end
    else if isInterface then
    begin
      jsonFieldProperties.fieldValue := objectMethod.Invoke(value, []);
    end
    else
    begin
      jsonFieldProperties.fieldValue := objectMethod.Invoke(value.AsObject, []);
    end;

    // serialize
    SerializeFieldUsingProvidedProperties(objectMethod.ReturnType);

  end;

  context.stream.WriteEndObject;

end;

procedure SerializeInternal(value: TValue; context: TSerContext; nullIfEmptyString: Boolean = false);
var
  dataType: TRttiType;
begin
  // check for the type and call the appropriate subroutine for serialization
  dataType := context.RTTI.GetType(value.TypeInfo);

  // check if it a object and
  if value.IsObject then
  begin
    // check if the object was already / is in the process of being serialized
    if context.IsTracked(value.AsObject) then
    begin
      raise EDJCycleError.Create('A cycle was detected during serialization!',
        context.GetPath);
    end;
    context.Track(value.AsObject);
  end;

  // checking if a special case handled the type of data
  if SerHandledSpecialCase(value, dataType, context) then
  begin
    exit;
  end;

  // handle other cases
  if value.IsArray then
  begin
    SerArray(value, context);
  end
  else if value.Kind = TTypeKind.tkFloat then
  begin
    SerFloat(value, context);
  end
  else if value.Kind = TTypeKind.tkInt64 then
  begin
    SerInt64(value, context);
  end
  else if value.Kind = TTypeKind.tkInteger then
  begin
    SerInt(value, context);
  end
  else if value.IsType<string>(false) then
  begin
    SerString(value, context, nullIfEmptyString);
  end
  else if value.IsEmpty then
  begin
    context.stream.WriteValueNull();
  end
  else if value.IsType<Boolean> then
  begin
    context.stream.WriteValueBoolean(value.AsBoolean);
  end
  else if value.IsObject then
  begin
    SerObject(value, context, false, false);
  end
  else if value.Kind = TTypeKind.tkRecord then
  begin
    SerObject(value, context, true, false);
  end
  else if value.Kind = TTypeKind.tkMRecord then
  begin
    SerObject(value, context, true, false);
  end
  else if value.Kind = TTypeKind.tkInterface then
  begin
    SerObject(value, context, false, true);
  end
  else
  begin
    raise EDJError.Create('Type not supported for serialization. ',
      context.GetPath);
  end;
end;

function DerSpecialConstructors(dataType: TRttiType; method: TRttiMethod;
  var params: TArray<TValue>): Boolean;
begin
  Result := false;

  // special case dictionary constructor
  if dataType.Name.ToLower.StartsWith('tdictionary<') then
  begin
    if Length(method.GetParameters) = 1 then
    begin
      if method.GetParameters[0].Name.ToLower = 'acapacity' then
      begin
        Result := true;
        SetLength(params, 1);
        params[0] := TValue.From(0);
        exit;
      end;
    end;
  end;
end;

function DerConstructObject(dataType: TRttiType; context: TDerContext): TValue;
var
  objType: TRttiInstanceType;
  method: TRttiMethod;
  selectedMethod: TRttiMethod;

  tmp: TRttiParameter;
  counter: integer;

  BaseType: TRttiType;

  params: TArray<TValue>;
  attribute: TCustomAttribute;
  isSelectedConstructor: Boolean;
begin
  objType := dataType.AsInstance;

  // find correct constructor (since create is not always supported with no arguments)
  // idea: Iterate over all constructors of the instance and choose a fitting one by the following priority:
  // 1. Check if there are special cases (E.g. TDictionary, ...) and use the hardcoded constructors
  // 2. use one tagged with the [DJConstructorAttribute]
  // 3. use the [Create] constructor (if it does not need any arguments)
  // otherwise an error is thrown, since no valid constructor was found

  selectedMethod := nil;

  SetLength(params, 0);

  for method in objType.GetMethods do
  begin
    isSelectedConstructor := false;

    if not method.IsConstructor then
    begin
      continue;
    end;

    // this is used to handle special cases of the standard library
    if DerSpecialConstructors(dataType, method, params) then
    begin
      selectedMethod := method;
      continue;
    end;

    for attribute in method.GetAttributes do
    begin
      if attribute is DJConstructorAttribute then
      begin
        isSelectedConstructor := true;
        break;
      end;
    end;

    if not isSelectedConstructor then
    begin
      // further searching for constructors
      if not(method.Visibility in [TMemberVisibility.mvPublished,
        TMemberVisibility.mvPublic]) then
      begin
        continue;
      end;

      if method.Name.ToLower <> 'create' then
      begin
        continue;
      end;
    end;

    // checking the number of parameters
    counter := 0;
    for tmp in method.GetParameters do
    begin
      // Ideal case: check if a default value is set and use it (This is sadly (currently) not possible with RTTI)
      Inc(counter);
    end;
    if counter <> 0 then
    begin
      continue;
    end;

    // checking if the currently selected method should be replaced
    if selectedMethod <> nil then
    begin

      if selectedMethod.Parent = method.Parent then
      begin
        if isSelectedConstructor then
        begin
          // only replace the constructor of the same class with one from the same class if it is the choosen one
          selectedMethod := method;
        end;
      end
      else
      begin
        // check if the selected constructor is from a base class of the current one being checked (if so, replace it)
        BaseType := method.Parent;
        while BaseType <> nil do
        begin
          if BaseType = selectedMethod.Parent then
          begin
            // the selected constructor is from a base class, hence choose the current "higher" constructor
            selectedMethod := method;
          end;
          BaseType := BaseType.BaseType;
        end;
      end;
    end
    else
    begin
      selectedMethod := method;
    end;

  end;

  if selectedMethod = nil then
  begin
    raise EDJError.Create('Did not find a suitable constructor for type. ',
      context.GetPath);
  end;

  Result := selectedMethod.Invoke(objType.MetaclassType, params);
  context.AddHeapObject(Result.AsObject);
end;

function DerArray(dataType: TRttiType; context: TDerContext): TValue;
var
  res: array of TValue;
  valueType: TRttiType;
  i: integer;
  staticType: TRttiArrayType;
begin
  context.stream.ReadStepInto;

  if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    // dynamic array
    SetLength(res, 0);
    i := 0;

    valueType := TRttiDynamicArrayType(dataType).ElementType;
    while not context.stream.ReadIsDone do
    begin
      SetLength(res, Length(res) + 1);

      context.PushPath(i.ToString);
      res[High(res)] := DeserializeInternal(valueType, context);
      context.PopPath;

      Inc(i);
      context.stream.ReadNext;
    end;
    Result := TValue.FromArray(dataType.Handle, res);
  end
  else
  begin
    // static array
    staticType := TRttiArrayType(dataType);

    SetLength(res, 0);
    i := 0;

    valueType := staticType.ElementType;
    while not context.stream.ReadIsDone do
    begin
      SetLength(res, Length(res) + 1);

      context.PushPath(i.ToString);
      res[High(res)] := DeserializeInternal(valueType, context);
      context.PopPath;

      Inc(i);
      context.stream.ReadNext;
    end;

    // check length of array
    if staticType.TotalElementCount <> Length(res) then
    begin
      raise EDJWrongArraySizeError.Create
        ('Element count of the given JSON array does not match the size of a static array. ',
        context.GetPath);
    end;

    Result := TValue.FromArray(staticType.Handle, res);
  end;

  context.stream.ReadStepOut;
end;

function DerNumber(dataType: TRttiType; context: TDerContext): TValue;
var
  valFloat: double;
  valInt64: Int64;
  valInt: integer;
begin
  if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    // floating point number
    valFloat := context.stream.ReadValueFloat;
    Result := TValue.From(valFloat);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    // integer 64 bit number
    valInt64 := context.stream.ReadValueInteger;
    Result := TValue.From(valInt64);
  end
  else
  begin
    // int number
    valInt := context.stream.ReadValueInteger;
    Result := TValue.From(valInt);
  end;
end;

function DerBool(dataType: TRttiType; context: TDerContext): TValue;
begin
  Result := TValue.From(context.stream.ReadValueBoolean);
end;

function DerString(dataType: TRttiType; context: TDerContext): TValue;
var
  val: string;
begin
  val := context.stream.ReadValueString;
  Result := TValue.From(val);
end;

procedure DerTDictionaryStringKey(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  addMethod: TRttiMethod;

  propertyName: string;
  valueKey: TValue;
  // typeKey: TRttiType;
  valueValue: TValue;
  typeValue: TRttiType;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstObject
  then
  begin
    raise EDJError.Create('Expected a JSON object. ', context.GetPath);
  end;
  context.stream.ReadStepInto;

  // create object
  objOut := DerConstructObject(dataType, context);

  // get the method that we will use to add into the dictionary
  addMethod := dataType.GetMethod('AddOrSetValue');

  // get the types of the key and value
  // typeKey := addMethod.GetParameters[0].ParamType; // this should be a string
  typeValue := addMethod.GetParameters[1].ParamType;

  while not context.stream.ReadIsDone do
  begin
    propertyName := context.stream.ReadPropertyName;
    valueKey := TValue.From<string>(propertyName);

    // deserialize value
    context.PushPath(propertyName);
    valueValue := DeserializeInternal(typeValue, context);
    context.PopPath;

    // add the deserialized values to the dictionary
    addMethod.Invoke(objOut, [valueKey, valueValue]);

    context.stream.ReadNext;
  end;

  context.stream.ReadStepOut;
end;

procedure DerTDictionary(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  addMethod: TRttiMethod;

  valueKey: TValue;
  typeKey: TRttiType;
  valueValue: TValue;
  typeValue: TRttiType;

  foundKey: Boolean;
  foundValue: Boolean;
  propertyName: string;
  i: integer;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstArray
  then
  begin
    raise EDJError.Create('Expected a JSON array. ', context.GetPath);
  end;

  context.stream.ReadStepInto;

  // construct object
  objOut := DerConstructObject(dataType, context);

  // get the method that we will use to add into the dictionary
  addMethod := dataType.GetMethod('AddOrSetValue');

  // get the types of the key and value
  typeKey := addMethod.GetParameters[0].ParamType;
  typeValue := addMethod.GetParameters[1].ParamType;

  i := 0;
  while not context.stream.ReadIsDone do
  begin
    context.PushPath(i);

    // split up array entry into key and value and check if this went fine
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstObject
    then
    begin
      raise EDJError.Create('Expected a JSON object. ', context.GetPath);
    end;

    foundKey := false;
    foundValue := false;

    context.stream.ReadStepInto;
    while not context.stream.ReadIsDone do
    begin
      if foundKey and foundValue then
      begin
        break;
      end;

      propertyName := context.stream.ReadPropertyName;
      if propertyName = 'key' then
      begin
        foundKey := true;

        // deserialize key
        context.PushPath('key');
        valueKey := DeserializeInternal(typeKey, context);
        context.PopPath;
      end
      else if propertyName = 'value' then
      begin
        foundValue := true;

        // deserialize value
        context.PushPath('value');
        valueValue := DeserializeInternal(typeValue, context);
        context.PopPath;
      end;
      context.stream.ReadNext;
    end;
    context.stream.ReadStepOut;

    if not foundKey then
    begin
      raise EDJError.Create('Expected a field with name "key". ',
        context.GetPath);
    end;

    if not foundValue then
    begin
      raise EDJError.Create('Expected a field with name "value". ',
        context.GetPath);
    end;

    // add the deserialized values to the dictionary
    addMethod.Invoke(objOut, [valueKey, valueValue]);

    context.PopPath;

    Inc(i);
    context.stream.ReadNext;
  end;
  context.stream.ReadStepOut;

end;

procedure DerTPair(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  typeKey: TRttiType;
  typeValue: TRttiType;

  foundKey: Boolean;
  foundValue: Boolean;

  propertyName: string;

  valueKey: TValue;
  valueValue: TValue;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstObject
  then
  begin
    raise EDJError.Create('Expected a JSON object. ', context.GetPath);
  end;

  context.stream.ReadStepInto;

  foundKey := false;
  foundValue := false;

  while not context.stream.ReadIsDone do
  begin
    if foundKey and foundValue then
    begin
      break;
    end;

    propertyName := context.stream.ReadPropertyName;
    if propertyName = 'key' then
    begin
      foundKey := true;

      // deserialize key
      context.PushPath('key');
      typeKey := dataType.GetField('Key').fieldType;
      valueKey := DeserializeInternal(typeKey, context);
      context.PopPath;
    end
    else if propertyName = 'value' then
    begin
      foundValue := true;

      // deserialize value
      typeValue := dataType.GetField('Value').fieldType;
      context.PushPath('value');
      valueValue := DeserializeInternal(typeValue, context);
      context.PopPath;
    end;

    context.stream.ReadNext;
  end;
  context.stream.ReadStepOut;

  if not foundKey then
  begin
    raise EDJError.Create('Expected a field with name "key". ',
      context.GetPath);
  end;

  if not foundValue then
  begin
    raise EDJError.Create('Expected a field with name "value". ',
      context.GetPath);
  end;

  // create pair
  // TODO: check if this is correct. (alternative TValue.Empty.Cast(type) )
  TValue.Make(nil, dataType.Handle, objOut);

  // apply the values to the object
  dataType.GetField('Key').SetValue(objOut.AsObject, valueKey);
  dataType.GetField('Value').SetValue(objOut.AsObject, valueValue);

  context.stream.ReadStepOut;
end;

procedure DerTEnumerable(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  addMethod: TRttiMethod;
  ElementType: TRttiType;

  i: integer;
  elementValue: TValue;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstArray
  then
  begin
    raise EDJError.Create('Expected a JSON array. ', context.GetPath);
  end;

  context.stream.ReadStepInto;

  // construct object
  objOut := DerConstructObject(dataType, context);

  addMethod := dataType.GetMethod('Add');
  if addMethod = nil then
  begin
    addMethod := dataType.GetMethod('Enqueue');
  end;
  if addMethod = nil then
  begin
    addMethod := dataType.GetMethod('Push');
  end;
  if addMethod = nil then
  begin
    raise EDJError.Create
      ('Could not find a method to add items to the object. ', context.GetPath);
  end;
  ElementType := addMethod.GetParameters[0].ParamType;

  i := 0;
  while not context.stream.ReadIsDone do
  begin

    context.PushPath(i.ToString);
    elementValue := DeserializeInternal(ElementType, context);
    context.PopPath;

    // add the element value to the object
    addMethod.Invoke(objOut, [elementValue]);

    context.stream.ReadNext;
    Inc(i);
  end;

  context.stream.ReadStepOut;
end;

procedure DerTDateTime(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  str: string;
  dt: TDateTime;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
  then
  begin
    raise EDJError.Create
      ('Expected a JSON string in date time ISO 8601 format.', context.GetPath);
  end;

  str := context.stream.ReadValueString;
  try
    dt := ISO8601ToDate(str, context.settings.DateTimeReturnUTC);
  except
    on E: exception do
    begin
      raise EDJFormatError.Create
        ('Invalid DateTime format was provided. Expected an ISO 8601 ' +
        'formatted string.', context.GetPath);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTDate(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
const
  format = 'yyyy-mm-dd';
var
  str: string;
  dt: TDate;
  fmt: TFormatSettings;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
  then
  begin
    raise EDJError.Create('Expected a JSON string in date format.',
      context.GetPath);
  end;

  str := context.stream.ReadValueString;
  try
    fmt := TFormatSettings.Create('en-US');
    fmt.LongDateFormat := format;
    fmt.ShortDateFormat := format;
    fmt.DateSeparator := '-';
    dt := StrToDateTime(str, fmt);
  except
    on E: exception do
    begin
      raise EDJFormatError.Create
        ('Invalid Date format was provided. Expected an "' + format +
        '" formatted string.', context.GetPath);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTTime(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
const
  format = 'hh:nn:ss.z';
var
  str: string;
  dt: TTime;
  fmt: TFormatSettings;
begin
  if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
  then
  begin
    raise EDJError.Create('Expected a JSON string in time format.',
      context.GetPath);
  end;

  str := context.stream.ReadValueString;
  try
    fmt := TFormatSettings.Create('en-US');
    fmt.LongTimeFormat := format;
    fmt.ShortTimeFormat := format;
    fmt.TimeSeparator := ':';
    dt := StrToDateTime(str, fmt);
  except
    on E: exception do
    begin
      raise EDJFormatError.Create
        ('Invalid DateTime format was provided. Expected an "' + format +
        '" formatted string.', context.GetPath);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTJSONValue(dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  output: TJSONValue;
begin
  output := context.stream.ReadAsTJsonValue;
  context.AddHeapObject(output);
  objOut := TValue.From(output);
end;

function DerHandledSpecialCase(dataType: TRttiType; var objOut: TValue;
  context: TDerContext): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.ToLower = 'tdatetime' then
    begin
      Result := true;
      DerTDateTime(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower = 'tdate' then
    begin
      Result := true;
      DerTDate(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower = 'ttime' then
    begin
      Result := true;
      DerTTime(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower = 'tjsonvalue' then
    begin
      Result := true;
      DerTJSONValue(dataType, objOut, context);
      exit;
    end;

    if context.settings.TreatStringDictionaryAsObject and
      (tmp.Name.ToLower.StartsWith('tdictionary<system.string,', true) or
      tmp.Name.ToLower.StartsWith('tdictionary<string,', true)) then
    begin
      Result := true;
      DerTDictionaryStringKey(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tdictionary<', true) then
    begin
      Result := true;
      DerTDictionary(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tpair<', true) then
    begin
      Result := true;
      DerTPair(dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tenumerable<', true) then
    begin
      Result := true;
      DerTEnumerable(dataType, objOut, context);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := false;
end;

function DerGetDefaultValue(dataType: TRttiType; context: TDerContext;
  attr: IDJDefaultValue): TValue;
var
  attrType: TRttiType;
  methods: TArray<TRttiMethod>;
  method: TRttiMethod;

  variantType: TRttiType;
  variantResult: TValue;
  variantValue: Variant;
begin
  // function IsVariant: Boolean; virtual; abstract;
  // function GetValue: Variant;
  // function GetValue: T

  attrType := context.RTTI.GetType(attr.ClassType);

  // retrieve the get value method
  methods := attrType.GetMethods('GetValue');
  if Length(methods) = 0 then
  begin
    raise EDJError.Create
      ('Could not find function "GetValue" on default value attribute!',
      context.GetPath);
  end;
  method := methods[Low(methods)];

  // check if method does not need any parameters
  if Length(method.GetParameters) > 0 then
  begin
    raise EDJError.Create
      ('Function "GetValue" takes more than zero parameters on default value attribute!',
      context.GetPath);
  end;

  if attr.IsVariant then
  begin
    // verify that the return type is a variant
    variantType := context.RTTI.GetType(System.TypeInfo(Variant));
    if method.ReturnType <> variantType then
    begin
      raise EDJError.Create
        ('Function "GetValue" did not return a variant although it was promised by function "IsVariant" on default value attribute!',
        context.GetPath);
    end;

    // get the variant result
    variantResult := method.Invoke(attr, []);
    variantValue := variantResult.AsType<Variant>;

    // convert single to double or the other way around if required
    if (VarType(variantValue) = varSingle) and
      (dataType = context.RTTI.GetType(System.TypeInfo(double))) then
    begin
      variantValue := VarAsType(variantValue, varDouble);
    end
    else if (VarType(variantValue) = varDouble) and
      (dataType = context.RTTI.GetType(System.TypeInfo(single))) then
    begin
      variantValue := VarAsType(variantValue, varSingle);
    end;

    Result := TValue.FromVariant(variantValue);

    // check its type integrity
    variantType := context.RTTI.GetType(Result.TypeInfo);
    if variantType <> dataType then
    begin
      raise EDJError.Create
        ('Data type of variant does not match the annotated fields type on default value attribute!',
        context.GetPath);
    end;
  end
  else
  begin
    // check the result type
    if method.ReturnType <> dataType then
    begin
      raise EDJError.Create
        ('Result type of "GetValue" does not match the annotated fields type on default value attribute!',
        context.GetPath);
    end;

    // get the default value
    Result := method.Invoke(attr, []);
  end;
end;

function DerUsingConverter(dataType: TRttiType; context: TDerContext;
  converter: IDJConverterInterface): TValue;
var
  converterType: TRttiType;
  streamType: TRttiType;
  methods: TArray<TRttiMethod>;
  method: TRttiMethod;
  parameters: TArray<TRttiParameter>;
  resultType: TRttiType;
  streamParameter: TRttiParameter;
begin
  // The following function needs to be implemented in the converter
  // function FromJSON(stream: TDJJsonStream): T; virtual; abstract;

  converterType := context.RTTI.GetType(converter.ClassType);
  streamType := context.RTTI.GetType(System.TypeInfo(TDJJsonStream));

  // get "ToJSON" method from converter
  methods := converterType.GetMethods('FromJSON');
  if Length(methods) = 0 then
  begin
    raise EDJError.Create('Could not find method "FromJSON" on converter!',
      context.GetPath);
  end;
  method := methods[Low(methods)];

  // get parameter and result types and verify their correctness
  parameters := method.GetParameters;
  if Length(parameters) <> 2 then
  begin
    raise EDJError.Create
      ('Invalid amount of parameters for method "FromJSON" on converter!',
      context.GetPath);
  end;

  resultType := method.ReturnType;
  streamParameter := parameters[Low(parameters)];

  if resultType <> dataType then
  begin
    raise EDJError.Create
      ('Result type does not match the annotated fields type for method "FromJSON" on converter!',
      context.GetPath);
  end;

  if streamParameter.ParamType <> streamType then
  begin
    raise EDJError.Create
      ('Type of stream field does not match TDJJsonStream for method "FromJSON" on converter!',
      context.GetPath);
  end;

  // TODO: check type of settings parameter

  // invoke the method after everything else seems fine
  Result := method.Invoke(converter, [TValue.From<TDJJsonStream>(context.stream), TValue.From<TDJSettings>(context.settings)]);

end;

function DerObject(dataType: TRttiType; context: TDerContext;
  isRecord: Boolean): TValue;
type
  TFieldData = record
    field: TRttiField;
    jsonFieldName: string;
    nillable: Boolean;
    required: Boolean;
    defaultValue: IDJDefaultValue;
    nilIsDefault: Boolean;
    converter: IDJConverterInterface;
  end;
var
  methods: TArray<TRttiMethod>;
  tmpMethod: TRttiMethod;

  objValue: TValue;

  attribute: TCustomAttribute;
  found: Boolean;

  objectFields: TArray<TRttiField>;
  rttifield: TRttiField;
  propertyName: string;

  fieldValue: TValue;

  allowUnusedFields: Boolean;

  propertiesUsed: integer;
  propertiesCount: integer;

  fieldData: TFieldData;
  fieldDictionary: TDictionary<string, TFieldData>;
  method: TObject;
begin

  fieldDictionary := nil;
  try
    fieldDictionary := TDictionary<string, TFieldData>.Create;

    // handle a "standard" object and deserialize it
    allowUnusedFields := context.settings.AllowUnusedJSONFields;
    found := false;
    for attribute in dataType.GetAttributes() do
    begin
      if attribute is DJSerializableAttribute then
      begin
        found := true;
      end
      else if attribute is DJNoUnusedJSONFieldsAttribute then
      begin
        allowUnusedFields := not(attribute as DJNoUnusedJSONFieldsAttribute)
          .noUnusedFields;
      end;
    end;

    if context.settings.RequireSerializableAttributeForNonRTLClasses then
    begin
      // Ensure the object has the serializable attribute.
      if not found then
      begin
        raise EDJError.Create
          ('Given object type is missing the JSONSerializable attribute. ',
          context.GetPath);
      end;
    end;

    // check if there is a function with a DJFromJSONFunctionAttribute
    methods := dataType.GetMethods;
    for tmpMethod in methods do
    begin
      for attribute in tmpMethod.GetAttributes do
      begin
        if attribute is DJFromJSONFunctionAttribute then
        begin
          // we found a DJFromJSONFunctionAttribute, deserialize using the class function
          if (not tmpMethod.IsClassMethod) or (not tmpMethod.IsStatic) then
          begin
            raise EDJError.Create
              ('Given function marked with DJFromJSONFunctionAttribute is not a static class function. ',
              context.GetPath);
          end;

          // check that the return type matches the current data type
          if tmpMethod.ReturnType.Name <> tmpMethod.Parent.Name then
          begin
            raise EDJError.Create
              ('Given function marked with DJFromJSONFunctionAttribute has an invalid return type. Expected "' +
              tmpMethod.Parent.Name + '" but got "' + tmpMethod.ReturnType.Name + '". ',
              context.GetPath);
          end;

          var
            allowUsageOfAnnotatedFunction: Boolean := true;

          if (attribute as DJFromJSONFunctionAttribute).doNotInherit then
          begin
            if dataType.Name <> tmpMethod.Parent.Name then
            begin
              // the current data type does not match the type which defines the function
              // and since doNotInherit is set to true, we do not want to use the
              // annotated function in this case
              allowUsageOfAnnotatedFunction := false;
            end;
          end;

          if allowUsageOfAnnotatedFunction then
          begin
            Result := tmpMethod.Invoke(nil, [context.stream, context.settings]);
            exit;
          end;
        end;
      end;
    end;

    // check if the value is null
    if context.stream.ReadGetType = TDJJsonStream.TDJJsonStreamTypes.djstNull then
    begin
      if dataType.Handle^.Kind = TTypeKind.tkClass then
      begin
        Result := TValue.From<TObject>(nil);
        exit;
      end
      else if (dataType.Handle^.Kind = TTypeKind.tkRecord) or (dataType.Handle^.Kind = TTypeKind.tkMRecord) then
      begin
        raise EDJError.Create('Record type can not be null. ', context.GetPath);
      end
      else
      begin
        raise exception.Create('Unexpected data type!');
      end;
    end;

    // check if the json data provides an object
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstObject
    then
    begin
      raise EDJError.Create('Expected a JSON object!', context.GetPath);
    end;

    // create an empty instance of the object
    if isRecord then
    begin
      // create a record value
      TValue.Make(nil, dataType.Handle, objValue);
    end
    else
    begin
      // create a new instance of the object
      objValue := DerConstructObject(dataType, context);
    end;

    // check if this is a json object
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstObject
    then
    begin
      raise EDJError.Create('Expected a JSON Object. ', context.GetPath);
    end;
    context.stream.ReadStepInto;

    objectFields := dataType.GetFields;
    for rttifield in objectFields do
    begin
      // define the standard properties for a field
      found := false;
      fieldData.jsonFieldName := '';
      fieldData.nillable := true;
      fieldData.required := context.settings.RequiredByDefault;
      fieldData.defaultValue := nil;
      fieldData.nilIsDefault := false;
      fieldData.converter := nil;

      fieldData.field := rttifield;

      for attribute in rttifield.GetAttributes() do
      begin
        if attribute is DJValueAttribute then
        begin
          // found the value attribute (this needs to be serialized)
          found := true;
          fieldData.jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
        end
        else if attribute is DJNonNilableAttribute then
        begin
          // nil is not allowed
          fieldData.nillable := false;
        end
        else if attribute is DJRequiredAttribute then
        begin
          fieldData.required := (attribute as DJRequiredAttribute).required;
        end
        else if attribute is IDJDefaultValue then
        begin
          fieldData.defaultValue := attribute as IDJDefaultValue;
        end
        else if attribute is DJDefaultOnNilAttribute then
        begin
          fieldData.nilIsDefault := true;
        end
        else if attribute is IDJConverterInterface then
        begin
          fieldData.converter := attribute as IDJConverterInterface;
        end;;
      end;

      // check if nillable is allowed
      if context.settings.IgnoreNonNillable then
      begin
        fieldData.nillable := true;
      end;

      if found then
      begin
        // check if the field name is valid
        if string.IsNullOrWhiteSpace(fieldData.jsonFieldName) then
        begin
          raise EDJError.Create
            ('Invalid JSON field name: is null or whitespace. ',
            context.GetPath);
        end;

        // check if field name was used twice
        if fieldDictionary.ContainsKey(fieldData.jsonFieldName) then
        begin
          raise EDJError.Create('JSON Field name "' + fieldData.jsonFieldName +
            '" was assigned to two variables!', context.GetPath);
        end;

        // add field to dictionary
        fieldDictionary.Add(fieldData.jsonFieldName, fieldData);
      end;
    end;

    // read the json values of the object
    propertiesUsed := 0;
    propertiesCount := 0;
    while not context.stream.ReadIsDone do
    begin
      Inc(propertiesCount);

      propertyName := context.stream.ReadPropertyName;
      if not fieldDictionary.TryGetValue(propertyName, fieldData) then
      begin
        context.stream.ReadNext;
        continue;
      end;

      // use the json value provided
      Inc(propertiesUsed);

      // remove it from the dictionary
      fieldDictionary.Remove(propertyName);

      // check if null is a valid json value
      if context.stream.ReadGetType = TDJJsonStream.TDJJsonStreamTypes.djstNull
      then
      begin
        if not fieldData.nillable then
        begin
          context.PushPath(propertyName);
          raise EDJNilError.Create
            ('Field value must not be nil, but JSON was null for field with name "'
            + propertyName + '". ', context.GetPath);
        end
        else if fieldData.nilIsDefault then
        begin
          if fieldData.defaultValue <> nil then
          begin
            // a default value is defined, use it
            context.PushPath(propertyName);
            fieldValue := DerGetDefaultValue(fieldData.field.fieldType, context,
              fieldData.defaultValue);
            if fieldValue.IsObject then
            begin
              context.AddHeapObject(fieldValue.AsObject);
            end;
            context.PopPath;

            // set the value in the resulting object
            if isRecord then
            begin
              fieldData.field.SetValue(objValue.GetReferenceToRawData,
                fieldValue);
            end
            else
            begin
              fieldData.field.SetValue(objValue.AsObject, fieldValue);
            end;

            context.stream.ReadNext;
            continue;
          end
          else
          begin
            raise EDJError.Create
              ('Field should use a default value if JSON was null, but no default value attribute was defined for field with name "'
              + propertyName + '". ', context.GetPath);
          end;
        end;
      end;

      // check for converters
      context.PushPath(propertyName);
      if fieldData.converter <> nil then
      begin
        // converter deserialization
        fieldValue := DerUsingConverter(fieldData.field.fieldType, context,
          fieldData.converter);
      end
      else
      begin
        if context.stream.ReadGetType = TDJJsonStream.TDJJsonStreamTypes.djstNull
        then
        begin
          // field is allowed to be null and is null, hence set it to the empty value
          fieldValue := TValue.Empty;
        end
        else
        begin
          // default deserialization
          fieldValue := DeserializeInternal(fieldData.field.fieldType, context);
        end;
      end;
      context.PopPath;

      // set the value in the resulting object
      if isRecord then
      begin
        fieldData.field.SetValue(objValue.GetReferenceToRawData, fieldValue);
      end
      else
      begin
        fieldData.field.SetValue(objValue.AsObject, fieldValue);
      end;

      context.stream.ReadNext;
    end;

    // check for all unused fields and set their default values or raise an error
    // if required
    for fieldData in fieldDictionary.Values do
    begin
      if fieldData.required then
      begin
        // the field is required but was not found
        raise EDJRequiredError.Create('Value with name "' +
          fieldData.jsonFieldName + '" missing in JSON data. ',
          context.GetPath);
      end
      else
      begin
        // the field is not required and the field was not found, use the
        // default value(if existing) and continue with the next field
        if fieldData.defaultValue <> nil then
        begin
          // a default value is defined, use it
          context.PushPath(fieldData.jsonFieldName);
          fieldValue := DerGetDefaultValue(fieldData.field.fieldType, context,
            fieldData.defaultValue);
          if fieldValue.IsObject then
          begin
            context.AddHeapObject(fieldValue.AsObject);
          end;
          context.PopPath;

          // set the default value in the resulting object
          if isRecord then
          begin
            fieldData.field.SetValue(objValue.GetReferenceToRawData,
              fieldValue);
          end
          else
          begin
            fieldData.field.SetValue(objValue.AsObject, fieldValue);
          end;

        end;

        // at this point we took care of this object (either by assigning a
        // default value or by leaving it as it is)
      end;
    end;

    // check if there were unused fields and if that is not allowed
    if not allowUnusedFields then
    begin
      if propertiesCount > propertiesUsed then
      begin
        raise EDJUnusedFieldsError.Create('JSON object contains unused fields.',
          context.GetPath);
      end;
    end;

    // step out of the object
    context.stream.ReadStepOut;

    // return the object
    Result := objValue;
  finally
    fieldDictionary.Free;
  end;
end;

function DeserializeInternal(dataType: TRttiType; context: TDerContext): TValue;
const
  typeMismatch = 'JSON value type does not match field type. ';
begin

  // handle special cases before
  if DerHandledSpecialCase(dataType, Result, context) then
  begin
    exit;
  end;

  if dataType.Handle^.Kind = TTypeKind.tkArray then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstArray
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerArray(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstArray
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerArray(dataType, context);
  end
  else if dataType.Handle = System.TypeInfo(Boolean) then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstBoolean
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerBool(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstNumberInt
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerNumber(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInteger then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstNumberInt
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerNumber(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    if not(context.stream.ReadGetType
      in [TDJJsonStream.TDJJsonStreamTypes.djstNumberFloat,
      TDJJsonStream.TDJJsonStreamTypes.djstNumberInt]) then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerNumber(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkString then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerString(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkWString then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerString(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkUString then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerString(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkLString then
  begin
    if context.stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString
    then
    begin
      raise EDJError.Create(typeMismatch, context.GetPath);
    end;
    Result := DerString(dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkClass then
  begin
    Result := DerObject(dataType, context, false);
  end
  else if (dataType.Handle^.Kind = TTypeKind.tkRecord) or (dataType.Handle^.Kind = TTypeKind.tkMRecord) then
  begin
    Result := DerObject(dataType, context, true);
  end
  else
  begin
    raise EDJError.Create
      ('Type of field is not supported for deserialization. ', context.GetPath);
  end;
end;

{DelphiJSON<T>}

constructor DelphiJSON<T>.Create;
var
  tmp: TSerContext;
begin
  tmp := nil;
  raise EDJError.Create('Do not create instances of this object!', []);
end;

class function DelphiJSON<T>.Deserialize(data: String;
  settings: TDJSettings): T;
var
  val: TJSONValue;
begin
  val := TJSONObject.ParseJSONValue(data, true, true);
  try
    Result := DeserializeJ(val, settings);
  finally
    FreeAndNil(val);
  end;
end;

class function DelphiJSON<T>.DeserializeFromStream(stream: TDJJsonStream; settings: TDJSettings): T;
var
  context: TDerContext;
  rttiType: TRttiType;
  res: TValue;
  createdSettings: TDJSettings;
begin
  createdSettings := nil;
  if settings = nil then
  begin
    createdSettings := TDJSettings.Default;
    settings := createdSettings;
  end;

  context := TDerContext.Create;
  context.settings := settings;
  context.stream := stream;

  try
    rttiType := context.RTTI.GetType(System.TypeInfo(T));
    res := DeserializeInternal(rttiType, context);
  except
    on E: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise;
    end;
  end;

  context.Free;
  createdSettings.Free;
  Result := res.AsType<T>();
end;

class function DelphiJSON<T>.DeserializeJ(data: TJSONValue;
  settings: TDJSettings): T;
var
  stream: TDJJsonStream;
begin
  stream := TDJTJsonValueStream.CreateReader(data, false);
  try
    Result := DeserializeFromStream(stream, settings);
  finally
    FreeAndNil(stream);
  end;
end;

class function DelphiJSON<T>.Serialize(data: T; settings: TDJSettings): string;
var
  JsonValue: TJSONValue;
begin
  JsonValue := nil;
  try
    JsonValue := SerializeJ(data, settings);
    Result := JsonValue.ToJSON;
  except
    on E: EDJError do
    begin
      JsonValue.Free;
      raise;
    end;
  end;
  JsonValue.Free;
end;

class procedure DelphiJSON<T>.SerializeIntoStream(data: T; stream: TDJJsonStream; settings: TDJSettings);
var
  valueObject: TValue;
  context: TSerContext;
  createdSettings: TDJSettings;
begin
  createdSettings := nil;
  if settings = nil then
  begin
    createdSettings := TDJSettings.Default;
    settings := createdSettings;
  end;

  context := TSerContext.Create;
  context.settings := settings;
  context.stream := stream;

  try
    valueObject := TValue.From<T>(data);
    SerializeInternal(valueObject, context);
  except
    on E: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise;
    end;
  end;

  context.Free;
  createdSettings.Free;
end;

class function DelphiJSON<T>.SerializeJ(data: T; settings: TDJSettings)
  : TJSONValue;
var
  stream: TDJTJsonValueStream;
begin
  stream := TDJTJsonValueStream.CreateWriter;
  try
    SerializeIntoStream(data, stream, settings);
    Result := stream.ExtractWrittenValue;
  finally
    FreeAndNil(stream);
  end;
end;

{TSerContext}

procedure TSerContext.AddHeapObject(obj: TObject);
begin
  heapAllocatedObjects.AddOrSetValue(obj, false);
end;

constructor TSerContext.Create;
begin
  self.path := TStack<string>.Create;
  self.RTTI := TRttiContext.Create;
  self.heapAllocatedObjects := TDictionary<TObject, Boolean>.Create;
  self.objectTracker := TDictionary<TObject, Boolean>.Create;
end;

destructor TSerContext.Destroy;
begin
  self.path.Free;
  self.path := nil;
  self.RTTI.Free;
  self.heapAllocatedObjects.Clear;
  self.heapAllocatedObjects.Free;
  self.heapAllocatedObjects := nil;
  self.objectTracker.Free;
  self.objectTracker := nil;
end;

procedure TSerContext.FreeAllHeapObjects;
var
  obj: TObject;
  freed: Boolean;
begin
  // nil every reference to an object in a json value annotated fields in every
  // data that was created by the (de)serializer
  // this prevents double freeing due to objects being managed by their
  // parent objects and additionally being freed here

  for obj in heapAllocatedObjects.Keys do
  begin
    NilAllReferencesRecursive(TValue.From(obj));
  end;

  // free every heap object
  for obj in heapAllocatedObjects.Keys do
  begin
    freed := heapAllocatedObjects[obj];
    if not freed then
    begin
      heapAllocatedObjects[obj] := true;
      obj.Free;
    end;
  end;
end;

function TSerContext.GetPath: TArray<string>;
var
  tmp: string;
  i: integer;
begin
  SetLength(Result, self.path.Count);
  i := Low(Result);
  for tmp in self.path do
  begin
    if i > High(Result) then
    begin
      raise exception.Create('Invalid array index!');
    end;
    Result[i] := tmp;
    Inc(i);
  end;

end;

function TSerContext.IsTracked(obj: TObject): Boolean;
begin
  if obj = nil then
  begin
    Result := false;
  end;
  Result := self.objectTracker.ContainsKey(obj);
end;

procedure TSerContext.NilAllReferencesRecursive(value: TValue);
var
  dataType: TRttiType;
  field: TRttiField;
  attribute: TCustomAttribute;
  found: Boolean;
  fieldValue: TValue;
begin
  if not((value.TypeInfo.Kind = TTypeKind.tkRecord) or
    (value.IsObject and (value.AsObject <> nil))) then
  begin
    // the value is neither an object nor a record
    exit;
  end;

  dataType := RTTI.GetType(value.TypeInfo);

  // checking all fields
  for field in dataType.GetFields do
  begin
    found := false;
    for attribute in field.GetAttributes do
    begin
      if attribute is DJValueAttribute then
      begin
        found := true;
        break;
      end;
    end;

    if not found then
    begin
      continue;
    end;

    // get the field value
    if value.IsObject then
    begin
      // class object
      fieldValue := field.GetValue(value.AsObject);
    end
    else
    begin
      // record
      fieldValue := field.GetValue(value.GetReferenceToRawData);
    end;

    // nil the values of that field
    NilAllReferencesRecursive(fieldValue);

    // nil the field if it was an object
    if fieldValue.IsObject then
    begin
      if value.IsObject then
      begin
        // class object
        field.SetValue(value.AsObject, TValue.Empty);
      end
      else
      begin
        // record
        field.SetValue(value.GetReferenceToRawData, TValue.Empty);
      end;
    end;
  end;

end;

procedure TSerContext.PopPath;
begin
  path.Pop;
end;

procedure TSerContext.PushPath(index: integer);
begin
  path.Push(index.ToString);
end;

procedure TSerContext.RemoveHeapObject(obj: TObject);
begin
  heapAllocatedObjects.Remove(obj);
end;

procedure TSerContext.PushPath(val: string);
begin
  path.Push(val);
end;

procedure TSerContext.Track(obj: TObject);
begin
  if obj = nil then
  begin
    exit;
  end;
  self.objectTracker.AddOrSetValue(obj, true);
end;

{$ENDREGION}

{$REGION 'Attributes Implementation'}

{DJFromJSONFunctionAttribute}

constructor DJFromJSONFunctionAttribute.Create(const doNotInherit: Boolean);
begin
  inherited Create;
  self.doNotInherit := doNotInherit;
end;

{DJValueAttribute}

constructor DJValueAttribute.Create(const Name: string);
begin
  self.Name := name;
end;

{DJDefaultValueAttribute}

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

{DJNoUnusedJSONFieldsAttribute}

constructor DJNoUnusedJSONFieldsAttribute.Create(const noUnusedFields: Boolean);
begin
  self.noUnusedFields := noUnusedFields;
end;

{DJRequiredAttribute}

constructor DJRequiredAttribute.Create(const required: Boolean);
begin
  self.required := required;
end;

{DJDefaultValueCreatorAttribute<T>}

function DJDefaultValueCreatorAttribute<T>.GetValue: T;
begin
  Result := self.Generator;
end;

function DJDefaultValueCreatorAttribute<T>.IsVariant: Boolean;
begin
  Result := false;
end;

{DJConverterAttribute<T>}

function DJConverterAttribute<T>.Dummy: Boolean;
begin
  Result := true;
end;

{$ENDREGION}

{$REGION 'Types (Streams, Settings, Errors)'}

{TDJSettings}

constructor TDJSettings.Default;
begin
  RequireSerializableAttributeForNonRTLClasses := true;
  DateTimeReturnUTC := true;
  IgnoreNonNillable := false;
  RequiredByDefault := true;
  TreatStringDictionaryAsObject := true;
  AllowUnusedJSONFields := true;

  self.CustomProperties := TDictionary<String, String>.Create;
end;

destructor TDJSettings.Destroy;
begin
  FreeAndNil(self.CustomProperties);
  inherited;
end;

{EDJError}

constructor EDJError.Create(errorMessage: String; path: TArray<String>);
begin
  inherited Create(errorMessage + ' - ' + PathToString(path));
  self.errorMessage := errorMessage;
  self.path := path;
end;

destructor EDJError.Destroy;
begin
  inherited;
end;

function EDJError.FullPath: string;
begin
  Result := EDJError.PathToString(self.path);
end;

class function EDJError.PathToString(path: TArray<String>): String;
var
  ele: String;
begin
  Result := '';
  for ele in path do
  begin
    if Result.Length = 0 then
    begin
      Result := ele;
    end
    else
    begin
      Result := Result + '>' + ele;
    end;
  end;
end;

{TDJTJsonValueStream}

constructor TDJTJsonValueStream.CreateReader(value: TJSONValue;
  readRootValueOwnedByStream: Boolean);
begin
  self.isInReadMode := true;
  self.readActiveValue := TStack<TJSONValue>.Create;
  self.readPointer := TStack<integer>.Create;
  self.readRootValue := value;
  self.readRootValueOwnedByStream := readRootValueOwnedByStream;
end;

constructor TDJTJsonValueStream.CreateWriter;
begin
  self.isInReadMode := false;
  self.writeNextPropertyName := '';
  self.writeActiveValue := TStack<TJSONValue>.Create;
  self.writeRootValue := nil;
end;

destructor TDJTJsonValueStream.Destroy;
begin
  if isInReadMode then
  begin
    FreeAndNil(readActiveValue);
    FreeAndNil(readPointer);
    if self.readRootValueOwnedByStream then
    begin
      FreeAndNil(self.readRootValue);
    end;
  end
  else
  begin
    FreeAndNil(writeActiveValue);
    FreeAndNil(writeRootValue);
  end;
  inherited;
end;

function TDJTJsonValueStream.ExtractWrittenValue: TJSONValue;
begin
  Result := self.writeRootValue;
  self.writeRootValue := nil;
end;

class function TDJTJsonValueStream.GetTypeOfValue(value: TJSONValue)
  : TDJJsonStream.TDJJsonStreamTypes;
begin
  Result := djstNull;
  if value is TJSONNull then
  begin
    Result := djstNull;
  end
  else if value is TJSONBool then
  begin
    Result := djstBoolean;
  end
  else if value is TJSONObject then
  begin
    Result := djstObject;
  end
  else if value is TJSONArray then
  begin
    Result := djstArray;
  end
  else if value is TJSONNumber then
  begin
    if value.ToJSON.Contains('.') then
    begin
      Result := djstNumberFloat;
    end
    else
    begin
      Result := djstNumberInt;
    end;
  end
  else if value is TJSONString then
  begin
    Result := djstString;
  end;
end;

function TDJTJsonValueStream.ReadGetPointedPropertyName: String;
var
  activeValue: TJSONValue;
  pointer: integer;
  obj: TJSONObject;
begin
  if self.readActiveValue.Count = 0 then
  begin
    raise exception.Create('No active object!');
  end
  else
  begin
    activeValue := self.readActiveValue.Peek;
    pointer := self.readPointer.Peek;
    if activeValue is TJSONObject then
    begin
      obj := activeValue as TJSONObject;
      if pointer >= obj.Count then
      begin
        raise exception.Create('Pointer out of bounds');
      end
      else
      begin
        Result := obj.Pairs[pointer].JsonString.value;
      end;
    end
    else
    begin
      raise exception.Create('Active value has illegal type!');
    end;
  end;
end;

function TDJTJsonValueStream.ReadGetPointedTJSONValue: TJSONValue;
var
  activeValue: TJSONValue;
  pointer: integer;
  arr: TJSONArray;
  obj: TJSONObject;
begin
  if self.readActiveValue.Count = 0 then
  begin
    Result := self.readRootValue;
  end
  else
  begin
    activeValue := self.readActiveValue.Peek;
    pointer := self.readPointer.Peek;

    if activeValue is TJSONArray then
    begin
      arr := activeValue as TJSONArray;
      if pointer >= arr.Count then
      begin
        Result := nil;
      end
      else
      begin
        Result := arr[pointer];
      end;
    end
    else if activeValue is TJSONObject then
    begin
      obj := activeValue as TJSONObject;
      if pointer >= obj.Count then
      begin
        Result := nil;
      end
      else
      begin
        Result := obj.Pairs[pointer].JsonValue;
      end;
    end
    else
    begin
      raise exception.Create('Active value has illegal type!');
    end;
  end;
end;

function TDJTJsonValueStream.ReadGetType: TDJJsonStream.TDJJsonStreamTypes;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := self.ReadGetPointedTJSONValue;
  Result := TDJTJsonValueStream.GetTypeOfValue(pointedValue);
end;

function TDJTJsonValueStream.ReadIsDone: Boolean;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := self.ReadGetPointedTJSONValue;
  if pointedValue = nil then
  begin
    Result := true;
  end
  else
  begin
    Result := false;
  end;
end;

function TDJTJsonValueStream.ReadIsRoot: Boolean;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  Result := self.readActiveValue.Count = 0;
end;

procedure TDJTJsonValueStream.ReadNext;
var
  pointer: integer;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  if self.readActiveValue.Count = 0 then
  begin
    raise exception.Create('Active value is not an array or object!');
  end;

  pointer := self.readPointer.Pop;
  Inc(pointer);
  self.readPointer.Push(pointer);
end;

function TDJTJsonValueStream.ReadPropertyName: String;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  if self.readActiveValue.Count = 0 then
  begin
    raise exception.Create('Active value is not an object!');
  end;
  if not(self.readActiveValue.Peek is TJSONObject) then
  begin
    raise exception.Create('Active value is not an object!');
  end;

  Result := self.ReadGetPointedPropertyName;
end;

procedure TDJTJsonValueStream.ReadStepInto;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := self.ReadGetPointedTJSONValue;
  if pointedValue = nil then
  begin
    raise exception.Create('Pointer is not pointing towards any value');
  end;

  if (not(pointedValue is TJSONObject)) and (not(pointedValue is TJSONArray))
  then
  begin
    raise exception.Create('Pointed value is not an array or object');
  end;

  self.readActiveValue.Push(pointedValue);
  self.readPointer.Push(0);
end;

procedure TDJTJsonValueStream.ReadStepOut;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;

  if self.readActiveValue.Count = 0 then
  begin
    raise exception.Create('Can not step out if not inside an object or array');
  end;

  self.readActiveValue.Pop;
  self.readPointer.Pop;
end;

function TDJTJsonValueStream.ReadValueBoolean: Boolean;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := ReadGetPointedTJSONValue;
  if not(pointedValue is TJSONBool) then
  begin
    raise exception.Create
      ('Invalid type of json value! Check type before accessing the value');
  end;
  Result := (pointedValue as TJSONBool).AsBoolean;
end;

function TDJTJsonValueStream.ReadValueFloat: double;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := ReadGetPointedTJSONValue;
  if not(pointedValue is TJSONNumber) then
  begin
    raise exception.Create
      ('Invalid type of json value! Check type before accessing the value');
  end;
  Result := (pointedValue as TJSONNumber).AsDouble;
end;

function TDJTJsonValueStream.ReadValueInteger: Int64;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := ReadGetPointedTJSONValue;
  if not(pointedValue is TJSONNumber) then
  begin
    raise exception.Create
      ('Invalid type of json value! Check type before accessing the value');
  end;
  Result := (pointedValue as TJSONNumber).AsInt64;
end;

function TDJTJsonValueStream.ReadValueIsNull: Boolean;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := ReadGetPointedTJSONValue;
  Result := pointedValue is TJSONNull;
end;

function TDJTJsonValueStream.ReadValueString: string;
var
  pointedValue: TJSONValue;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  pointedValue := ReadGetPointedTJSONValue;
  if not(pointedValue is TJSONString) then
  begin
    raise exception.Create
      ('Invalid type of json value! Check type before accessing the value');
  end;
  Result := (pointedValue as TJSONString).value;
end;

function TDJTJsonValueStream.ViewWrittenValue: TJSONValue;
begin
  Result := self.writeRootValue;
end;

procedure TDJTJsonValueStream.WriteBeginArray(const propertyName: string);
var
  arr: TJSONArray;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  arr := TJSONArray.Create;
  self.WriteJsonValue(arr, propertyName);
  self.writeActiveValue.Push(arr);
end;

procedure TDJTJsonValueStream.WriteBeginObject(const propertyName: string);
var
  obj: TJSONObject;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  obj := TJSONObject.Create;
  self.WriteJsonValue(obj, propertyName);
  self.writeActiveValue.Push(obj);
end;

procedure TDJTJsonValueStream.WriteEndArray;
var
  activeValue: TJSONValue;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  if self.writeActiveValue.Count = 0 then
  begin
    raise exception.Create('Active value is not an array!');
  end;
  activeValue := self.writeActiveValue.Peek;
  if not(activeValue is TJSONArray) then
  begin
    raise exception.Create('Active value is not an array!');
  end;
  self.writeActiveValue.Pop;
end;

procedure TDJTJsonValueStream.WriteEndObject;
var
  activeValue: TJSONValue;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  if self.writeActiveValue.Count = 0 then
  begin
    raise exception.Create('Active value is not an object!');
  end;
  activeValue := self.writeActiveValue.Peek;
  if not(activeValue is TJSONObject) then
  begin
    raise exception.Create('Active value is not an object!');
  end;
  self.writeActiveValue.Pop;
end;

function TDJTJsonValueStream.WriteGetActiveValue: TJSONValue;
begin
  if self.writeActiveValue.Count = 0 then
  begin
    Result := self.writeRootValue;
  end
  else
  begin
    Result := self.writeActiveValue.Peek;
  end;
end;

function TDJTJsonValueStream.WriteGetFinalPropertyName
  (propertyName: string): string;
begin
  Result := self.writeNextPropertyName;
  self.writeNextPropertyName := '';
  if propertyName <> '' then
  begin
    Result := propertyName;
  end;
end;

procedure TDJTJsonValueStream.WriteJsonValue(value: TJSONValue;
  propertyName: string);
var
  finalPropertyName: string;
  activeValue: TJSONValue;
  obj: TJSONObject;
  arr: TJSONArray;
begin
  finalPropertyName := WriteGetFinalPropertyName(propertyName);

  activeValue := WriteGetActiveValue;
  if activeValue = nil then
  begin
    if finalPropertyName <> '' then
    begin
      raise exception.Create
        ('Cannot have property names on an active value that is not an object!');
    end;
    self.writeRootValue := value;
  end
  else
  begin
    if activeValue is TJSONArray then
    begin
      if finalPropertyName <> '' then
      begin
        raise exception.Create
          ('Cannot have property names on an active value that is not an object!');
      end;
      arr := activeValue as TJSONArray;
      arr.AddElement(value);
    end
    else if activeValue is TJSONObject then
    begin
      if finalPropertyName = '' then
      begin
        raise exception.Create('Cannot have an empty property name!');
      end;
      obj := activeValue as TJSONObject;
      if obj.Get(finalPropertyName) <> nil then
      begin
        raise exception.Create
          ('Object already has a property with the specified name!');
      end;
      obj.AddPair(finalPropertyName, value);
    end
    else
    begin
      raise exception.Create
        ('Cannot add a value to an active object that is neither an array nor an object!');
    end;
  end;

end;

procedure TDJTJsonValueStream.WriteSetNextPropertyName
  (const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.writeNextPropertyName := propertyName;
end;

procedure TDJTJsonValueStream.WriteValueBoolean(value: Boolean;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteJsonValue(TJSONBool.Create(value), propertyName);
end;

procedure TDJTJsonValueStream.WriteValueFloat(const value: double;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteJsonValue(TJSONNumber.Create(value), propertyName);
end;

procedure TDJTJsonValueStream.WriteValueInteger(const value: Int64;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteJsonValue(TJSONNumber.Create(value), propertyName);
end;

procedure TDJTJsonValueStream.WriteValueNull(const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteJsonValue(TJSONNull.Create, propertyName);
end;

procedure TDJTJsonValueStream.WriteValueString(const value,
  propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteJsonValue(TJSONString.Create(value), propertyName);
end;

{TDJTJsonRWStream}

constructor TDJTJsonRWStream.CreateReader(reader: TJSONReader;
  readerOwnedByThisObject: Boolean);
begin
  self.isInReadMode := true;
  self.readReader := reader;
  self.readReaderOwnedByThisObject := readerOwnedByThisObject;
  self.readIterator := TJSONIterator.Create(self.readReader);
  self.readIsDoneFlag := self.readIterator.Next;
  self.readLastPropertyName := '';
end;

constructor TDJTJsonRWStream.CreateWriter(writer: TJSONWriter;
  writerOwnedByThisObject: Boolean);
begin
  self.isInReadMode := false;
  self.writeWriter := writer;
  self.writeWriterOwnedByThisObject := writerOwnedByThisObject;
  self.writeNextPropertyName := '';
end;

destructor TDJTJsonRWStream.Destroy;
begin
  if self.isInReadMode then
  begin
    if self.readReaderOwnedByThisObject then
    begin
      FreeAndNil(self.readReader);
    end
    else
    begin
      self.readReader := nil;
    end;
    FreeAndNil(self.readIterator);
  end
  else
  begin
    if self.writeWriterOwnedByThisObject then
    begin
      FreeAndNil(self.writeWriter);
    end
    else
    begin
      self.writeWriter := nil;
    end;
  end;
  inherited;
end;

function TDJTJsonRWStream.ReadGetType: TDJJsonStream.TDJJsonStreamTypes;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  // SEE: https://docwiki.embarcadero.com/Libraries/Sydney/de/System.JSON.Builders.TJSONIterator

end;

function TDJTJsonRWStream.ReadIsDone: Boolean;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  Result := self.readIsDoneFlag;
end;

function TDJTJsonRWStream.ReadIsRoot: Boolean;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  Result := self.readIterator.Depth = 0;
end;

procedure TDJTJsonRWStream.ReadNext;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  self.readIsDoneFlag := self.readIterator.Next;
end;

function TDJTJsonRWStream.ReadPropertyName: String;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  if self.readLastPropertyName = '' then
  begin
    raise exception.Create('Cannot read property name in this context!');
  end;
  Result := self.readLastPropertyName;
end;

procedure TDJTJsonRWStream.ReadStepInto;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  self.readIterator.Recurse;
end;

procedure TDJTJsonRWStream.ReadStepOut;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
  self.readIterator.Return;
end;

function TDJTJsonRWStream.ReadValueBoolean: Boolean;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
end;

function TDJTJsonRWStream.ReadValueFloat: double;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
end;

function TDJTJsonRWStream.ReadValueInteger: Int64;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
end;

function TDJTJsonRWStream.ReadValueIsNull: Boolean;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
end;

function TDJTJsonRWStream.ReadValueString: string;
begin
  if not self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is write only but a read method was called!');
  end;
end;

procedure TDJTJsonRWStream.WriteBeginArray(const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteStartArray;
end;

procedure TDJTJsonRWStream.WriteBeginObject(const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteStartObject;
end;

procedure TDJTJsonRWStream.WriteEndArray;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.writeWriter.WriteEndArray;
end;

procedure TDJTJsonRWStream.WriteEndObject;
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.writeWriter.WriteEndObject;
end;

function TDJTJsonRWStream.WriteGetFinalPropertyName(propertyName
  : string): string;
begin
  Result := self.writeNextPropertyName;
  self.writeNextPropertyName := '';
  if propertyName <> '' then
  begin
    Result := propertyName;
  end;
end;

procedure TDJTJsonRWStream.WriteSetNextPropertyName(const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.writeNextPropertyName := propertyName;
end;

procedure TDJTJsonRWStream.WriteValueBoolean(value: Boolean;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteValue(value);
end;

procedure TDJTJsonRWStream.WriteValueFloat(const value: double;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteValue(value);
end;

procedure TDJTJsonRWStream.WriteValueInteger(const value: Int64;
  const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteValue(value);
end;

procedure TDJTJsonRWStream.WriteValueNull(const propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteNull;
end;

procedure TDJTJsonRWStream.WriteValueString(const value, propertyName: string);
begin
  if self.isInReadMode then
  begin
    raise exception.Create
      ('Stream is read only but a write method was called!');
  end;
  self.WriteWriteFinalPropertyName(propertyName);
  self.writeWriter.WriteValue(value);
end;

procedure TDJTJsonRWStream.WriteWriteFinalPropertyName(propertyName: string);
var
  finalPropertyName: string;
begin
  finalPropertyName := self.WriteGetFinalPropertyName(propertyName);
  if finalPropertyName <> '' then
  begin
    self.writeWriter.WritePropertyName(finalPropertyName);
  end;
end;

{TDJJsonStreamHelper}

function TDJJsonStreamHelper.ReadAsTJsonValue: TJSONValue;
var
  T: TDJJsonStreamTypes;

  tmpObject: TJSONObject;
  tmpArray: TJSONArray;

  tmpPropertyName: string;
  tmpValue: TJSONValue;
begin
  try
    T := self.ReadGetType;

    case T of
      djstObject:
        begin
          tmpObject := TJSONObject.Create;
          Result := tmpObject;

          self.ReadStepInto;
          while not self.ReadIsDone do
          begin
            tmpPropertyName := self.ReadPropertyName;
            tmpValue := self.ReadAsTJsonValue;
            tmpObject.AddPair(tmpPropertyName, tmpValue);
            self.ReadNext;
          end;
          self.ReadStepOut;

        end;
      djstArray:
        begin
          tmpArray := TJSONArray.Create;
          Result := tmpArray;

          self.ReadStepInto;
          while not self.ReadIsDone do
          begin
            tmpValue := self.ReadAsTJsonValue;
            tmpArray.AddElement(tmpValue);
            self.ReadNext;
          end;
          self.ReadStepOut;
        end;
      djstNull:
        begin
          Result := TJSONNull.Create;
        end;
      djstBoolean:
        begin
          Result := TJSONBool.Create(self.ReadValueBoolean)
        end;
      djstNumberInt:
        begin
          Result := TJSONNumber.Create(self.ReadValueInteger);
        end;
      djstNumberFloat:
        begin
          Result := TJSONNumber.Create(self.ReadValueFloat);
        end;
      djstString:
        begin
          Result := TJSONString.Create(self.ReadValueString);
        end;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TDJJsonStreamHelper.WriteTJsonValue(value: TJSONValue; const propertyName: string);
var
  tmpArray: TJSONArray;
  tmpObject: TJSONObject;

  tmpValue: TJSONValue;
  tmpPropertyName: string;
  tmpPair: TJSONPair;
begin
  if value is TJSONNull then
  begin
    self.WriteValueNull(propertyName);
  end
  else if value is TJSONBool then
  begin
    self.WriteValueBoolean((value as TJSONBool).AsBoolean, propertyName);
  end
  else if value is TJSONNumber then
  begin
    if value.ToJSON.Contains('.') then
    begin
      // float
      self.WriteValueFloat((value as TJSONNumber).AsDouble, propertyName);
    end
    else
    begin
      // integer
      self.WriteValueInteger((value as TJSONNumber).AsInt64, propertyName);
    end;
  end
  else if value is TJSONString then
  begin
    self.WriteValueString((value as TJSONString).value, propertyName);
  end
  else if value is TJSONArray then
  begin
    tmpArray := value as TJSONArray;
    self.WriteBeginArray(propertyName);
    for tmpValue in tmpArray do
    begin
      self.WriteTJsonValue(tmpValue);
    end;
    self.WriteEndArray;
  end
  else if value is TJSONObject then
  begin
    tmpObject := value as TJSONObject;
    self.WriteBeginObject(propertyName);
    for tmpPair in tmpObject do
    begin
      tmpValue := tmpPair.JsonValue;
      tmpPropertyName := tmpPair.JsonString.value;
      self.WriteTJsonValue(tmpValue, tmpPropertyName);
    end;
    self.WriteEndObject;
  end;

end;

{$ENDREGION}

initialization

begin
  // create the unit wide used rtti context

  // This is done to provide thread safety!
  // The context only provides a reference to the global reference counted rtti context
  // singleton. The singleton gets freed if there are no references left and is recreated
  // if not existing. The reference / free / recreate part seems to not be thread safe
  // and caused access violations.
  // If we always keep at least one reference to the context object like here, this issue
  // is no longer a problem.

  unitRttiContextInstance := TRttiContext.Create;
end;

finalization

begin
  // free the unit wide used rtti context
  unitRttiContextInstance.Free;
end;

end.
