///
/// DelphiJSON Library - Copyright (c) 2021 Corbinian Gruber
///
/// Version: 1.0.0
///
/// This library is licensed under the MIT License.
/// https://github.com/gruco0002/DelphiJSON
///

unit DelphiJSONTypes;

interface

uses
  System.Generics.Collections, System.SysUtils, System.JSON;

type
  /// <summary>
  /// [TDJJsonStream] is an abstract class that provides the (de)serialization
  /// of DelphiJSON with an api for reading and writing JSON data. This allows
  /// using different JSON libraries and data structures like TJSONValue or
  /// LJsonTextReader from the RTL for the (de)serialization process.
  ///
  /// A default implementation for TJSONValue is provided further down.
  /// </summary>
  TDJJsonStream = class
  public type
    TDJJsonStreamTypes = (djstObject, djstArray, djstNull, djstBoolean,
      djstNumber, djstString);
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
    procedure WriteBeginObject(const propertyName: string = '');
      virtual; abstract;
    procedure WriteEndObject; virtual; abstract;
    procedure WriteBeginArray(const propertyName: string = '');
      virtual; abstract;
    procedure WriteEndArray; virtual; abstract;
    procedure WriteValueNull(const propertyName: string = ''); virtual;
      abstract;
    procedure WriteValueBoolean(value: Boolean;
      const propertyName: string = ''); virtual; abstract;
    procedure WriteValueString(const value: string;
      const propertyName: string = ''); virtual; abstract;
    procedure WriteValueInteger(const value: Int64;
      const propertyName: string = ''); virtual; abstract;
    procedure WriteValueFloat(const value: double;
      const propertyName: string = ''); virtual; abstract;

  public
    // helpers for standard conversion from/into TJSONValue
    function ReadAsTJsonValue: TJSONValue;
    procedure WriteTJsonValue(value: TJSONValue;
      const propertyName: string = '');
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
    /// Creates the default settings for (de)serialization.
    /// </summary>
    constructor Default;

  end;

  /// <summary>
  /// Describes an error that happened during deserialization.
  /// </summary>
  EDJError = class(Exception)
  public
    path: TArray<String>;
    errorMessage: String;
    constructor Create(errorMessage: String; const path: TArray<String>);
    destructor Destroy; override;
    function FullPath: string;
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

implementation

end.
