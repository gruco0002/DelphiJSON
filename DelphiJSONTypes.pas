///
/// DelphiJSON Library - Copyright (c) 2021 Corbinian Gruber
///
/// Version: 2.0.0
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

  public
    // helpers for standard conversion from/into TJSONValue

    /// <summary>
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
    readPointer: TStack<Integer>;
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

implementation

{ TDJJsonStream }

function TDJJsonStream.ReadAsTJsonValue: TJSONValue;
var
  t: TDJJsonStreamTypes;

  tmpObject: TJSONObject;
  tmpArray: TJSONArray;

  tmpPropertyName: string;
  tmpValue: TJSONValue;
begin
  try
    t := self.ReadGetType;

    case t of
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

procedure TDJJsonStream.WriteTJsonValue(value: TJSONValue;
  const propertyName: string);
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
    self.WriteValueString((value as TJSONString).value);
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

{ TDJSettings }

constructor TDJSettings.Default;
begin
  RequireSerializableAttributeForNonRTLClasses := true;
  DateTimeReturnUTC := true;
  IgnoreNonNillable := false;
  RequiredByDefault := true;
  TreatStringDictionaryAsObject := true;
  AllowUnusedJSONFields := true;
end;

{ EDJError }

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

{ TDJTJsonValueStream }

constructor TDJTJsonValueStream.CreateReader(value: TJSONValue;
  readRootValueOwnedByStream: Boolean);
begin
  self.isInReadMode := true;
  self.readActiveValue := TStack<TJSONValue>.Create;
  self.readPointer := TStack<Integer>.Create;
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
  else if value is TJSONString then
  begin
    Result := djstString;
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
  end;
end;

function TDJTJsonValueStream.ReadGetPointedPropertyName: String;
var
  activeValue: TJSONValue;
  pointer: Integer;
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
      if obj.Count >= pointer then
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
  pointer: Integer;
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
      if arr.Count >= pointer then
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
      if obj.Count >= pointer then
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
  pointer: Integer;
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

end.
