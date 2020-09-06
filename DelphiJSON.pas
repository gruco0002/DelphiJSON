///
/// DelphiJSON Library - Copyright (c) 2020 Corbinian Gruber
///
/// This library is licensed under the MIT License.
/// https://github.com/gruco0002/DelphiJSON
///

unit DelphiJSON;

interface

uses
  System.SysUtils, System.JSON, System.RTTI, System.Generics.Collections;

type

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
    /// Creates the default settings for (de)serialization.
    /// </summary>
    constructor Default;

  end;

  /// <summary>
  /// Static class that has functions for (de)serializing.
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
  /// </summary>
  IDJDefaultValue = class(TCustomAttribute)
  protected
    function GetValue: TValue; virtual; abstract;
  end;

  /// <summary>
  /// Defines a default value for a field that is used during deserialization.
  /// The default value is used if the field is not defined in the given JSON object.
  /// This attribute only supports primitive values.
  /// This attribute has no effect if not used together with either the [DJDefaultOnNilAttribute] or the [DJRequiredAttribute].
  /// </summary>
  DJDefaultValueAttribute = class(IDJDefaultValue)
  private
    value: TValue;
  protected
    function GetValue: TValue; override;
  public
    constructor Create(const value: string); overload;
    constructor Create(const value: integer); overload;
    constructor Create(const value: single); overload;
    constructor Create(const value: double); overload;
    constructor Create(const value: Boolean); overload;
    constructor Create(const value: TValue); overload;
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
    function GetValue: TValue; override; final;
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
    function ToJSONinternal(value: TValue): TJSONValue; virtual; abstract;
    function FromJSONinternal(value: TJSONValue): TValue; virtual; abstract;
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
    function ToJSONinternal(value: TValue): TJSONValue; override;
    function FromJSONinternal(value: TJSONValue): TValue; override;
  public
    function ToJSON(value: T): TJSONValue; virtual; abstract;
    function FromJSON(value: TJSONValue): T; virtual; abstract;
  end;

  /// <summary>
  /// Describes an error that happened during deserialization.
  /// </summary>
  EDJError = class(Exception)
  public
    path: String;
    errorMessage: String;
    constructor Create(errorMessage: String; path: String);
    function Clone: EDJError; virtual;
  end;

  /// <summary>
  /// This error is raised if an required field is not found in the JSON object.
  /// </summary>
  EDJRequiredError = class(EDJError);

  /// <summary>
  /// This error is raised if a field is nil/null although it is annotated with
  /// the [DJNonNilableAttribute].
  /// </summary>
  EDJNilError = class(EDJError);

  TSerContext = class
  private
    path: TStack<string>;

    // keeps track of heap allocated objects in order to free them, if an error happens and no value can be returned
    // this is implemented to avoid memory leaks through invalid json or parameters / other issues
    heapAllocatedObjects: TDictionary<TObject, Boolean>;

  public
    RTTI: TRttiContext;
    settings: TDJSettings;

    constructor Create;
    destructor Destroy; override;

    function FullPath: string;
    procedure PushPath(val: string); overload;
    procedure PushPath(index: integer); overload;
    procedure PopPath;

    procedure AddHeapObject(obj: TObject);
    procedure RemoveHeapObject(obj: TObject);
    procedure FreeAllHeapObjects;

    function ToString: string; override;

  end;

  TDerContext = TSerContext;

function SerializeInternal(value: TValue; context: TSerContext): TJSONValue;
function DeserializeInternal(value: TJSONValue; dataType: TRttiType;
  context: TDerContext): TValue;

implementation

uses
  System.TypInfo, System.DateUtils;

function SerArray(value: TValue; context: TSerContext): TJSONArray;
var
  size: integer;
  i: integer;
  tmp: TJSONValue;
begin
  Result := TJSONArray.Create;
  context.AddHeapObject(Result);
  size := value.GetArrayLength;
  for i := 0 to size - 1 do
  begin
    context.PushPath(i.ToString);
    tmp := SerializeInternal(value.GetArrayElement(i), context);
    context.RemoveHeapObject(tmp);
    Result.AddElement(tmp);
    context.PopPath;
  end;
end;

function SerFloat(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsType<single>());
  context.AddHeapObject(Result);
end;

function SerInt64(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInt64);
  context.AddHeapObject(Result);
end;

function SerInt(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInteger);
  context.AddHeapObject(Result);
end;

function SerString(value: TValue; context: TSerContext): TJSONString;
begin
  Result := TJSONString.Create(value.AsString);
  context.AddHeapObject(Result);
end;

function SerTEnumerable(data: TObject; dataType: TRttiType;
  context: TSerContext): TJSONArray;
var
  getEnumerator: TRttiMethod;
  enumerator: TValue;
  moveNext: TRttiMethod;
  currentProperty: TRttiProperty;
  currentValue: TValue;
  currentSerialized: TJSONValue;
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

  Result := TJSONArray.Create;
  context.AddHeapObject(Result);

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
    currentSerialized := SerializeInternal(currentValue, context);
    context.PopPath;
    context.RemoveHeapObject(currentSerialized);
    Result.AddElement(currentSerialized);

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
    moveNextResult := moveNextValue.AsBoolean;
    Inc(i);
  end;

  enumerator.AsObject.Free;

end;

function SerTDictionaryStringKey(data: TObject; dataType: TRttiType;
  context: TSerContext): TJSONObject;
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
  serializedValue: TJSONValue;

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

  Result := TJSONObject.Create;
  context.AddHeapObject(Result);

  // inital move
  moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
  moveNextResult := moveNextValue.AsBoolean;

  while moveNextResult do
  begin
    // retrieve current pair
    currentPairValue := currentProperty.GetValue(enumerator.AsObject);

    keyValue := keyField.GetValue(currentPairValue.AsObject);
    valueValue := valueField.GetValue(currentPairValue.AsObject);

    keyString := keyValue.AsString;

    context.PushPath(keyString);
    serializedValue := SerializeInternal(valueValue, context);
    context.PopPath;
    context.RemoveHeapObject(serializedValue);
    Result.AddPair(keyString, serializedValue);

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator.AsObject, []);
    moveNextResult := moveNextValue.AsBoolean;
  end;

  enumerator.AsObject.Free;

end;

function SerTPair(data: TValue; dataType: TRttiType; context: TSerContext)
  : TJSONObject;
var
  keyField: TRttiField;
  valueField: TRttiField;
  keyValue: TValue;
  valueValue: TValue;
  serializedKey: TJSONValue;
  serializedValue: TJSONValue;
begin
  keyField := dataType.GetField('Key');
  valueField := dataType.GetField('Value');

  keyValue := keyField.GetValue(data.GetReferenceToRawData);
  valueValue := valueField.GetValue(data.GetReferenceToRawData);

  context.PushPath('key');
  serializedKey := SerializeInternal(keyValue, context);
  context.PopPath;
  context.PushPath('value');
  serializedValue := SerializeInternal(valueValue, context);
  context.PopPath;

  Result := TJSONObject.Create;
  context.AddHeapObject(Result);
  context.RemoveHeapObject(serializedKey);
  Result.AddPair('key', serializedKey);
  context.RemoveHeapObject(serializedValue);
  Result.AddPair('value', serializedValue);

end;

function SerTDateTime(data: TValue; dataType: TRttiType; context: TSerContext)
  : TJSONString;
var
  dt: TDateTime;
  str: string;
begin
  dt := data.AsType<TDateTime>();
  str := DateToISO8601(dt, context.settings.DateTimeReturnUTC);
  Result := TJSONString.Create(str);
  context.AddHeapObject(Result);
end;

function SerHandledSpecialCase(data: TValue; dataType: TRttiType;
  var output: TJSONValue; context: TSerContext): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.ToLower = 'tdatetime' then
    begin
      Result := true;
      output := SerTDateTime(data, dataType, context);
      exit;
    end;

    if tmp.Name.StartsWith('TDictionary<string,', true) then
    begin
      Result := true;
      output := SerTDictionaryStringKey(data.AsObject, dataType, context);
      exit;
    end;

    if tmp.Name.StartsWith('TPair<', true) then
    begin
      Result := true;
      output := SerTPair(data, dataType, context);
      exit;
    end;

    if tmp.Name.StartsWith('TEnumerable<', true) then
    begin
      Result := true;
      output := SerTEnumerable(data.AsObject, dataType, context);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := False;
end;

function SerObject(value: TValue; context: TSerContext; isRecord: Boolean)
  : TJSONValue;
var
  // data: TObject;
  dataType: TRttiType;
  attribute: TCustomAttribute;
  found: Boolean;

  resultObject: TJSONObject;

  objectFields: TArray<TRttiField>;
  field: TRttiField;
  jsonFieldName: string;
  fieldValue: TValue;
  serializedField: TJSONValue;

  nillable: Boolean;
  converter: IDJConverterInterface;
begin

  dataType := context.RTTI.GetType(value.TypeInfo);

  // TODO: split this function in smaller parts

  // handle a "standard" object and serialize it

  if context.settings.RequireSerializableAttributeForNonRTLClasses then
  begin
    // Ensure the object has the serializable attribute. (Fields added later)
    found := False;
    for attribute in dataType.GetAttributes() do
    begin
      if attribute is DJSerializableAttribute then
      begin
        found := true;
        break;
      end;
    end;
    if not found then
    begin
      raise EDJError.Create
        ('Given object type is missing the JSONSerializable attribute. ',
        context.FullPath);
    end;
  end;

  // Init the result object
  resultObject := TJSONObject.Create;
  context.AddHeapObject(resultObject);
  Result := resultObject;

  // adding fields to the object
  objectFields := dataType.GetFields;
  for field in objectFields do
  begin
    // default values for properties
    found := False;
    nillable := true;
    converter := nil;

    // check for the attributes
    for attribute in field.GetAttributes() do
    begin
      if attribute is DJValueAttribute then
      begin
        // found the value attribute (this needs to be serialized)
        found := true;
        jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
      end
      else if attribute is DJNonNilableAttribute then
      begin
        // nil is not allowed
        nillable := False;
      end
      else if attribute is IDJConverterInterface then
      begin
        converter := attribute as IDJConverterInterface;
      end;
    end;

    // check if nillable is allowed
    if context.settings.IgnoreNonNillable then
    begin
      nillable := true;
    end;

    if not found then
    begin
      // skip this field since it is not opted-in for serialization
      continue;
    end;

    // check if the field name is valid
    if string.IsNullOrWhiteSpace(jsonFieldName) then
    begin
      raise EDJError.Create('Invalid JSON field name: is null or whitespace. ',
        context.FullPath);
    end;

    if isRecord then
    begin
      fieldValue := field.GetValue(value.GetReferenceToRawData);
    end
    else
    begin
      fieldValue := field.GetValue(value.AsObject);
    end;

    context.PushPath(jsonFieldName);

    // check if field is nil
    if fieldValue.IsObject then
    begin
      if (not nillable) and (fieldValue.AsObject = nil) then
      begin
        raise EDJNilError.Create('Field value must not be nil, but was nil. ',
          context.FullPath);
      end;
    end;

    // serialize
    if converter <> nil then
    begin
      // use the converter
      serializedField := converter.ToJSONinternal(fieldValue);
    end
    else
    begin
      // use the default serialization
      serializedField := SerializeInternal(fieldValue, context);
    end;
    context.PopPath;

    // add the variable to the resulting object
    context.RemoveHeapObject(serializedField);
    resultObject.AddPair(jsonFieldName, serializedField);

  end;

end;

function SerializeInternal(value: TValue; context: TSerContext): TJSONValue;
var
  dataType: TRttiType;
begin
  // check for the type and call the appropriate subroutine for serialization

  dataType := context.RTTI.GetType(value.TypeInfo);

  // checking if a special case handled the type of data
  if SerHandledSpecialCase(value, dataType, Result, context) then
  begin
    exit;
  end;

  // handle other cases
  if value.IsArray then
  begin
    Result := SerArray(value, context);
  end
  else if value.Kind = TTypeKind.tkFloat then
  begin
    Result := SerFloat(value, context);
  end
  else if value.Kind = TTypeKind.tkInt64 then
  begin
    Result := SerInt64(value, context);
  end
  else if value.Kind = TTypeKind.tkInteger then
  begin
    Result := SerInt(value, context);
  end
  else if value.IsType<string>(False) then
  begin
    Result := SerString(value, context);
  end
  else if value.IsEmpty then
  begin
    Result := TJSONNull.Create;
    context.AddHeapObject(Result);
  end
  else if value.IsType<Boolean> then
  begin
    Result := TJSONBool.Create(value.AsBoolean);
    context.AddHeapObject(Result);
  end
  else if value.IsObject then
  begin
    Result := SerObject(value, context, False);
  end
  else if value.Kind = TTypeKind.tkRecord then
  begin
    Result := SerObject(value, context, true);
  end
  else
  begin
    raise EDJError.Create('Type not supported for serialization. ',
      context.FullPath);
  end;
end;

function DerSpecialConstructors(dataType: TRttiType; method: TRttiMethod;
  var params: TArray<TValue>): Boolean;
begin
  Result := False;

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
    isSelectedConstructor := False;

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
      context.FullPath);
  end;

  Result := selectedMethod.Invoke(objType.MetaclassType, params);
  context.AddHeapObject(Result.AsObject);
end;

function DerArray(value: TJSONArray; dataType: TRttiType;
  context: TDerContext): TValue;
var
  res: array of TValue;
  valueType: TRttiType;
  i: integer;
  staticType: TRttiArrayType;
begin
  if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    // dynamic array
    SetLength(res, value.Count);
    valueType := TRttiDynamicArrayType(dataType).ElementType;
    for i := 0 to High(res) do
    begin
      context.PushPath(i.ToString);
      res[i] := DeserializeInternal(value.Items[i], valueType, context);
      context.PopPath;
    end;
    Result := TValue.FromArray(dataType.Handle, res);
  end
  else
  begin
    // static array
    staticType := TRttiArrayType(dataType);
    if staticType.TotalElementCount <> value.Count then
    begin
      raise EDJError.Create
        ('Element count of the given JSON array does not match the size of a static array. ',
        context.FullPath);
    end;

    SetLength(res, value.Count);
    valueType := staticType.ElementType;
    for i := 0 to High(res) do
    begin
      context.PushPath(i.ToString);
      res[i] := DeserializeInternal(value.Items[i], valueType, context);
      context.PopPath;
    end;
    Result := TValue.FromArray(staticType.Handle, res);
  end;
end;

function DerNumber(value: TJSONNumber; dataType: TRttiType;
  context: TDerContext): TValue;
var
  valFloat: double;
  valInt64: Int64;
  valInt: integer;
begin
  if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    // floating point number
    valFloat := value.AsDouble;
    Result := TValue.From(valFloat);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    // integer 64 bit number
    valInt64 := value.AsInt64;
    Result := TValue.From(valInt64);
  end
  else
  begin
    // int number
    valInt := value.AsInt;
    Result := TValue.From(valInt);
  end;
end;

function DerBool(value: TJSONBool; dataType: TRttiType;
  context: TDerContext): TValue;
begin
  Result := TValue.From(value.AsBoolean);
end;

function DerString(value: TJSONString; dataType: TRttiType;
  context: TDerContext): TValue;
var
  val: string;
begin
  val := value.value;
  Result := TValue.From(val);
end;

procedure DerTDictionaryStringKey(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext);
var
  jsonObject: TJSONObject;

  addMethod: TRttiMethod;

  jPair: TJSONPair;

  valueKey: TValue;
  // typeKey: TRttiType;
  valueValue: TValue;
  typeValue: TRttiType;

  i: integer;

begin
  if not(value is TJSONObject) then
  begin
    raise EDJError.Create('Expected a JSON object. ', context.FullPath);
  end;
  jsonObject := value as TJSONObject;

  // create object
  objOut := DerConstructObject(dataType, context);

  // get the method that we will use to add into the dictionary
  addMethod := dataType.GetMethod('AddOrSetValue');

  // get the types of the key and value
  // typeKey := addMethod.GetParameters[0].ParamType; // this should be a string
  typeValue := addMethod.GetParameters[1].ParamType;

  for i := 0 to jsonObject.Count - 1 do
  begin
    jPair := jsonObject.Pairs[i];
    valueKey := TValue.From<string>(jPair.JsonString.value);

    // deserialize value
    context.PushPath(jPair.JsonString.value);
    valueValue := DeserializeInternal(jPair.JsonValue, typeValue, context);
    context.PopPath;

    // add the deserialized values to the dictionary
    addMethod.Invoke(objOut, [valueKey, valueValue]);

  end;
end;

procedure DerTDictionary(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext);
var
  jsonArray: TJSONArray;

  addMethod: TRttiMethod;

  jArrValue: TJSONValue;
  jArrObject: TJSONObject;

  jsonKey: TJSONValue;
  JsonValue: TJSONValue;
  valueKey: TValue;
  typeKey: TRttiType;
  valueValue: TValue;
  typeValue: TRttiType;

  i: integer;
begin
  if not(value is TJSONArray) then
  begin
    raise EDJError.Create('Expected a JSON array. ', context.FullPath);
  end;
  jsonArray := value as TJSONArray;

  // construct object
  objOut := DerConstructObject(dataType, context);

  // get the method that we will use to add into the dictionary
  addMethod := dataType.GetMethod('AddOrSetValue');

  // get the types of the key and value
  typeKey := addMethod.GetParameters[0].ParamType;
  typeValue := addMethod.GetParameters[1].ParamType;

  for i := 0 to jsonArray.Count - 1 do
  begin
    context.PushPath(i);
    jArrValue := jsonArray.Items[i];

    // split up array entry into key and value and check if this went fine
    if not(jArrValue is TJSONObject) then
    begin
      raise EDJError.Create('Expected a JSON object. ', context.FullPath);
    end;
    jArrObject := jArrValue as TJSONObject;

    jsonKey := jArrObject.GetValue('key');
    if jsonKey = nil then
    begin
      raise EDJError.Create('Expected a field with name "key". ',
        context.FullPath);
    end;

    JsonValue := jArrObject.GetValue('value');
    if jsonKey = nil then
    begin
      raise EDJError.Create('Expected a field with name "value". ',
        context.FullPath);
    end;

    // deserialize key and value
    context.PushPath('key');
    valueKey := DeserializeInternal(jsonKey, typeKey, context);
    context.PopPath;
    context.PushPath('value');
    valueValue := DeserializeInternal(JsonValue, typeValue, context);
    context.PopPath;

    // add the deserialized values to the dictionary
    addMethod.Invoke(objOut, [valueKey, valueValue]);

    context.PopPath;

  end;

end;

procedure DerTPair(value: TJSONValue; dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
var
  jsonObject: TJSONObject;
  jsonKey: TJSONValue;
  JsonValue: TJSONValue;

  typeKey: TRttiType;
  typeValue: TRttiType;

  valueKey: TValue;
  valueValue: TValue;
begin
  if not(value is TJSONObject) then
  begin
    raise EDJError.Create('Expected a JSON object. ', context.FullPath);
  end;
  jsonObject := value as TJSONObject;

  jsonKey := jsonObject.GetValue('key');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "key". ',
      context.FullPath);
  end;

  JsonValue := jsonObject.GetValue('value');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "value". ',
      context.FullPath);
  end;

  // create pair
  // TODO: check if this is correct. (alternative TValue.Empty.Cast(type) )
  TValue.Make(nil, dataType.Handle, objOut);

  // deserialize values
  typeKey := dataType.GetField('Key').FieldType;
  typeValue := dataType.GetField('Value').FieldType;

  context.PushPath('key');
  valueKey := DeserializeInternal(jsonKey, typeKey, context);
  context.PopPath;
  context.PushPath('value');
  valueValue := DeserializeInternal(JsonValue, typeValue, context);
  context.PopPath;

  // apply the values to the object
  dataType.GetField('Key').SetValue(objOut.AsObject, valueKey);
  dataType.GetField('Value').SetValue(objOut.AsObject, valueValue);
end;

procedure DerTEnumerable(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext);
var
  jsonArray: TJSONArray;

  addMethod: TRttiMethod;
  ElementType: TRttiType;

  JsonValue: TJSONValue;
  i: integer;
  elementValue: TValue;

begin
  if not(value is TJSONArray) then
  begin
    raise EDJError.Create('Expected a JSON array. ', context.FullPath);
  end;
  jsonArray := value as TJSONArray;

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
      ('Could not find a method to add items to the object. ',
      context.FullPath);
  end;
  ElementType := addMethod.GetParameters[0].ParamType;

  for i := 0 to jsonArray.Count - 1 do
  begin

    JsonValue := jsonArray.Items[i];
    context.PushPath(i.ToString);
    elementValue := DeserializeInternal(JsonValue, ElementType, context);
    context.PopPath;

    // add the element value to the object
    addMethod.Invoke(objOut, [elementValue]);
  end;

end;

procedure DerTDateTime(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext);
var
  jStr: TJSONString;
  str: string;
  dt: TDateTime;
begin

  if not(value is TJSONString) then
  begin
    raise EDJError.Create('Expected a JSON string in date time format. ',
      context.FullPath);
  end;
  jStr := value as TJSONString;
  str := jStr.value;
  dt := ISO8601ToDate(str, context.settings.DateTimeReturnUTC);
  objOut := TValue.From(dt);
end;

function DerHandledSpecialCase(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.ToLower = 'tdatetime' then
    begin
      Result := true;
      DerTDateTime(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.StartsWith('TDictionary<string,', true) then
    begin
      Result := true;
      DerTDictionaryStringKey(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.StartsWith('TDictionary<', true) then
    begin
      Result := true;
      DerTDictionary(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.StartsWith('TPair<', true) then
    begin
      Result := true;
      DerTPair(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.StartsWith('TEnumerable<', true) then
    begin
      Result := true;
      DerTEnumerable(value, dataType, objOut, context);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := False;
end;

function DerObject(value: TJSONValue; dataType: TRttiType; context: TDerContext;
  isRecord: Boolean): TValue;
var
  objValue: TValue;

  jsonObject: TJSONObject;

  attribute: TCustomAttribute;
  found: Boolean;

  objectFields: TArray<TRttiField>;
  field: TRttiField;
  jsonFieldName: string;
  JsonValue: TJSONValue;

  fieldValue: TValue;

  nillable: Boolean;
  required: Boolean;
  defaultValue: IDJDefaultValue;
  nilIsDefault: Boolean;
  converter: IDJConverterInterface;
begin

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
  if not(value is TJSONObject) then
  begin
    raise EDJError.Create('Expected a JSON Object. ', context.FullPath);
  end;
  jsonObject := value as TJSONObject;

  // handle a "standard" object and deserialize it

  if context.settings.RequireSerializableAttributeForNonRTLClasses then
  begin
    // Ensure the object has the serializable attribute. (Fields added later)
    found := False;
    for attribute in dataType.GetAttributes() do
    begin
      if attribute is DJSerializableAttribute then
      begin
        found := true;
        break;
      end;
    end;
    if not found then
    begin
      raise EDJError.Create
        ('Given object type is missing the JSONSerializable attribute. ',
        context.FullPath);
    end;
  end;

  // getting fields from the object
  objectFields := dataType.GetFields;
  for field in objectFields do
  begin
    // define the standard properties for a field
    found := False;
    nillable := true;
    required := context.settings.RequiredByDefault;
    defaultValue := nil;
    nilIsDefault := False;
    converter := nil;

    // check for the attributes and update the properties
    for attribute in field.GetAttributes() do
    begin
      if attribute is DJValueAttribute then
      begin
        // found the value attribute (this needs to be serialized)
        found := true;
        jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
      end
      else if attribute is DJNonNilableAttribute then
      begin
        // nil is not allowed
        nillable := False;
      end
      else if attribute is DJRequiredAttribute then
      begin
        required := (attribute as DJRequiredAttribute).required;
      end
      else if attribute is IDJDefaultValue then
      begin
        defaultValue := attribute as IDJDefaultValue;
      end
      else if attribute is DJDefaultOnNilAttribute then
      begin
        nilIsDefault := true;
      end
      else if attribute is IDJConverterInterface then
      begin
        converter := attribute as IDJConverterInterface;
      end;
    end;

    // check if nillable is allowed
    if context.settings.IgnoreNonNillable then
    begin
      nillable := true;
    end;

    if not found then
    begin
      // skip this field since it is not opted-in for serialization
      continue;
    end;

    // check if the field name is valid
    if string.IsNullOrWhiteSpace(jsonFieldName) then
    begin
      raise EDJError.Create('Invalid JSON field name: is null or whitespace. ',
        context.FullPath);
    end;

    // check if the field name exists in the json structure

    JsonValue := jsonObject.GetValue(jsonFieldName);
    if required then
    begin
      // the field is required but was not found
      if JsonValue = nil then
      begin
        raise EDJRequiredError.Create('Value with name "' + jsonFieldName +
          '" missing in JSON data. ', context.FullPath);
      end;
    end
    else
    begin
      // the field is not required, check if it was found
      if JsonValue = nil then
      begin
        // the field was not found, use the default value (if existing) and continue with the next field

        if defaultValue <> nil then
        begin
          // a default value is defined, use it
          context.PushPath(jsonFieldName);
          fieldValue := defaultValue.GetValue;
          if fieldValue.IsObject then
          begin
            context.AddHeapObject(fieldValue.AsObject);
          end;
          context.PopPath;
        end;

        // set the value in the resulting object
        if isRecord then
        begin
          field.SetValue(objValue.GetReferenceToRawData, fieldValue);
        end
        else
        begin
          field.SetValue(objValue.AsObject, fieldValue);
        end;

        continue;
      end;
    end;

    if JsonValue is TJSONNull then
    begin
      if not nillable then
      begin
        raise EDJNilError.Create
          ('Field value must not be nil, but JSON was null for field with name "'
          + jsonFieldName + '". ', context.FullPath);
      end
      else if nilIsDefault then
      begin
        if defaultValue <> nil then
        begin
          // a default value is defined, use it
          context.PushPath(jsonFieldName);
          fieldValue := defaultValue.GetValue;
          if fieldValue.IsObject then
          begin
            context.AddHeapObject(fieldValue.AsObject);
          end;
          context.PopPath;

          // set the value in the resulting object
          if isRecord then
          begin
            field.SetValue(objValue.GetReferenceToRawData, fieldValue);
          end
          else
          begin
            field.SetValue(objValue.AsObject, fieldValue);
          end;

          continue;

        end
        else
        begin
          raise EDJError.Create
            ('Field should use a default value if JSON was null, but no default value attribute was defined for field with name "'
            + jsonFieldName + '". ', context.FullPath);
        end;
      end;
    end;

    context.PushPath(jsonFieldName);
    if converter <> nil then
    begin
      // converter deserialization
      fieldValue := converter.FromJSONinternal(JsonValue);
    end
    else
    begin
      // default deserialization
      fieldValue := DeserializeInternal(JsonValue, field.FieldType, context);
    end;
    context.PopPath;

    // set the value in the resulting object
    if isRecord then
    begin
      field.SetValue(objValue.GetReferenceToRawData, fieldValue);
    end
    else
    begin
      field.SetValue(objValue.AsObject, fieldValue);
    end;

  end;

  Result := objValue;

end;

function DeserializeInternal(value: TJSONValue; dataType: TRttiType;
  context: TDerContext): TValue;
const
  typeMismatch = 'JSON value type does not match field type. ';
begin

  // handle special cases before
  if DerHandledSpecialCase(value, dataType, Result, context) then
  begin
    exit;
  end;

  if dataType.Handle^.Kind = TTypeKind.tkArray then
  begin
    if not(value is TJSONArray) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    if not(value is TJSONArray) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle = System.TypeInfo(Boolean) then
  begin
    if not(value is TJSONBool) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerBool(value as TJSONBool, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInteger then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkWString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkUString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkLString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkClass then
  begin
    if value is TJSONNull then
    begin
      Result := TValue.From<TObject>(nil);
    end
    else if not(value is TJSONObject) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end
    else
    begin
      Result := DerObject(value as TJSONObject, dataType, context, False);
    end;
  end
  else if dataType.Handle^.Kind = TTypeKind.tkRecord then
  begin
    if value is TJSONNull then
    begin
      raise EDJError.Create('Record type can not be null. ', context.FullPath);
    end;

    if not(value is TJSONObject) then
    begin
      raise EDJError.Create(typeMismatch, context.FullPath);
    end;

    Result := DerObject(value as TJSONObject, dataType, context, true);

  end
  else
  begin
    raise EDJError.Create
      ('Type of field is not supported for deserialization. ',
      context.FullPath);
  end;
end;

{ DelphiJSON<T> }

constructor DelphiJSON<T>.Create;
begin
  raise EDJError.Create('Do not create instances of this object!', '');
end;

class function DelphiJSON<T>.Deserialize(data: String;
  settings: TDJSettings): T;
var
  val: TJSONValue;
begin
  val := nil;
  try
    val := TJSONObject.ParseJSONValue(data, true, true);
    Result := DeserializeJ(val, settings);
  except
    on e: EDJError do
    begin
      val.Free;
      raise e.Clone;
    end;
  end;
  val.Free;
end;

class function DelphiJSON<T>.DeserializeJ(data: TJSONValue;
  settings: TDJSettings): T;
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

  try
    rttiType := context.RTTI.GetType(System.TypeInfo(T));
    res := DeserializeInternal(data, rttiType, context);
  except
    on e: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise e.Clone;
    end;
  end;

  context.Free;
  createdSettings.Free;
  Result := res.AsType<T>();
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
    on e: EDJError do
    begin
      JsonValue.Free;
      raise e.Clone
    end;
  end;
  JsonValue.Free;
end;

class function DelphiJSON<T>.SerializeJ(data: T; settings: TDJSettings)
  : TJSONValue;
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

  try
    valueObject := TValue.From<T>(data);
    Result := SerializeInternal(valueObject, context);
  except
    on e: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise e.Clone
    end;
  end;

  context.Free;
  createdSettings.Free;
end;

{ DJValueAttribute }

constructor DJValueAttribute.Create(const Name: string);
begin
  self.Name := Name;
end;

{ TSerContext }

procedure TSerContext.AddHeapObject(obj: TObject);
begin
  heapAllocatedObjects.AddOrSetValue(obj, False);
end;

constructor TSerContext.Create;
begin
  self.path := TStack<string>.Create;
  self.RTTI := TRttiContext.Create;
  self.heapAllocatedObjects := TDictionary<TObject, Boolean>.Create;
end;

destructor TSerContext.Destroy;
begin
  self.path.Free;
  self.path := nil;
  self.RTTI.Free;
  self.heapAllocatedObjects.Clear;
  self.heapAllocatedObjects.Free;
  self.heapAllocatedObjects := nil;
end;

procedure TSerContext.FreeAllHeapObjects;
var
  obj: TObject;
  freed: Boolean;
begin
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

function TSerContext.FullPath: string;
var
  ele: string;
begin
  Result := '';
  for ele in path do
  begin
    Result := Result + '>' + ele;
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

function TSerContext.ToString: string;
begin
  Result := 'Context: { ' + FullPath + ' }';
end;

{ TDJSettings }

constructor TDJSettings.Default;
begin
  RequireSerializableAttributeForNonRTLClasses := true;
  DateTimeReturnUTC := true;
  IgnoreNonNillable := False;
  RequiredByDefault := true;
end;

{ DJDefaultValueAttribute }

constructor DJDefaultValueAttribute.Create(const value: single);
begin
  self.value := TValue.From(value);
end;

constructor DJDefaultValueAttribute.Create(const value: integer);
begin
  self.value := TValue.From(value);
end;

constructor DJDefaultValueAttribute.Create(const value: string);
begin
  self.value := TValue.From(value);
end;

constructor DJDefaultValueAttribute.Create(const value: TValue);
begin
  self.value := value;
end;

function DJDefaultValueAttribute.GetValue: TValue;
begin
  Result := self.value;
end;

constructor DJDefaultValueAttribute.Create(const value: Boolean);
begin
  self.value := TValue.From(value);
end;

constructor DJDefaultValueAttribute.Create(const value: double);
begin
  self.value := TValue.From(value);
end;

{ DJDefaultValueCreatorAttribute<T> }

function DJDefaultValueCreatorAttribute<T>.GetValue: TValue;
begin
  Result := TValue.From<T>(Generator());
end;

{ DJRequiredAttribute }

constructor DJRequiredAttribute.Create(const required: Boolean);
begin
  self.required := required;
end;

{ EDJError }

function EDJError.Clone: EDJError;
begin
  Result := EDJError.Create(self.errorMessage, self.path);
end;

constructor EDJError.Create(errorMessage, path: String);
begin
  inherited Create(errorMessage + ' - ' + path);
  self.errorMessage := errorMessage;
  self.path := path;
end;

{ DJConverterAttribute<T> }

function DJConverterAttribute<T>.FromJSONinternal(value: TJSONValue): TValue;
begin
  Result := TValue.From<T>(self.FromJSON(value));
end;

function DJConverterAttribute<T>.ToJSONinternal(value: TValue): TJSONValue;
begin
  Result := ToJSON(value.AsType<T>());
end;

end.
