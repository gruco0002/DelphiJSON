///
/// DelphiJSON Library - Copyright (c) 2021 Corbinian Gruber
///
/// Version: 2.0.0
///
/// This library is licensed under the MIT License.
/// https://github.com/gruco0002/DelphiJSON
///

unit DelphiJSON;

interface

uses
  System.SysUtils, System.JSON, System.RTTI, System.Generics.Collections,
  DelphiJSONAttributes, DelphiJSONTypes;

type

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

type
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

    stream: TDJJSONStream;

    constructor Create;
    destructor Destroy; override;

    function FullPath: string;
    function GetPath: TArray<string>;
    procedure PushPath(val: string); overload;
    procedure PushPath(index: integer); overload;
    procedure PopPath;

    procedure AddHeapObject(obj: TObject);
    procedure RemoveHeapObject(obj: TObject);
    procedure FreeAllHeapObjects;

    procedure Track(obj: TObject);
    function IsTracked(obj: TObject): Boolean;

    function ToString: string; override;

  end;

  TDerContext = TSerContext;

procedure SerializeInternal(value: TValue; context: TSerContext);
function DeserializeInternal(dataType: TRttiType; context: TDerContext): TValue;

implementation

uses
  System.TypInfo, System.DateUtils;

procedure SerArray(value: TValue; context: TSerContext);
var
  size: integer;
  i: integer;
  tmp: TJSONValue;
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

procedure SerString(value: TValue; context: TSerContext);
begin
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

  Result := False;
end;

procedure SerUsingConverter(value: TValue; dataType: TRttiType;
  converter: IDJConverterInterface; context: TSerContext);
begin
  // TODO: implement
end;

procedure SerObject(value: TValue; context: TSerContext; isRecord: Boolean);
var
  // data: TObject;
  dataType: TRttiType;
  attribute: TCustomAttribute;
  found: Boolean;

  objectFields: TArray<TRttiField>;
  field: TRttiField;
  jsonFieldName: string;
  fieldValue: TValue;

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
        ('Given object type is missing the JSONSerializable attribute.',
        context.GetPath);
    end;
  end;

  // Init the result object
  context.stream.WriteBeginObject();

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
        context.GetPath);
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
          context.GetPath);
      end;
    end;

    // serialize
    context.stream.WriteSetNextPropertyName(jsonFieldName);
    if converter <> nil then
    begin
      // use the converter
      SerUsingConverter(fieldValue, field.FieldType, converter, context);
    end
    else
    begin
      if fieldValue.IsObject and (fieldValue.AsObject = nil) then
      begin
        // field is nil and allowed to be nil, hence return a json null
        context.stream.WriteValueNull();
      end
      else
      begin
        // use the default serialization
        SerializeInternal(fieldValue, context);
      end;
    end;
    context.PopPath;
  end;

  context.stream.WriteEndObject;

end;

procedure SerializeInternal(value: TValue; context: TSerContext);
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
  else if value.IsType<string>(False) then
  begin
    SerString(value, context);
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
    SerObject(value, context, False);
  end
  else if value.Kind = TTypeKind.tkRecord then
  begin
    SerObject(value, context, true);
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
    Result := TValue.FromArray(staticType.Handle, res);

    if staticType.TotalElementCount <> Length(res) then
    begin
      raise EDJWrongArraySizeError.Create
        ('Element count of the given JSON array does not match the size of a static array. ',
        context.GetPath);
    end;
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
  if context.stream.ReadGetType <> TDJJSONStream.TDJJsonStreamTypes.djstObject
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
  if context.stream.ReadGetType <> TDJJSONStream.TDJJsonStreamTypes.djstArray
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
  while context.stream.ReadIsDone do
  begin
    context.PushPath(i);

    // split up array entry into key and value and check if this went fine
    if context.stream.ReadGetType <> TDJJSONStream.TDJJsonStreamTypes.djstObject
    then
    begin
      raise EDJError.Create('Expected a JSON object. ', context.GetPath);
    end;

    foundKey := False;
    foundValue := False;

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

// TODO: FIX STUFF FROM HERE ON DOWNWARDS
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
    raise EDJError.Create('Expected a JSON object. ', context);
  end;
  jsonObject := value as TJSONObject;

  jsonKey := jsonObject.GetValue('key');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "key". ', context);
  end;

  JsonValue := jsonObject.GetValue('value');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "value". ', context);
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
    raise EDJError.Create('Expected a JSON array. ', context);
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
      ('Could not find a method to add items to the object. ', context);
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
    raise EDJError.Create
      ('Expected a JSON string in date time ISO 8601 format.', context);
  end;
  jStr := value as TJSONString;
  str := jStr.value;
  try
    dt := ISO8601ToDate(str, context.settings.DateTimeReturnUTC);
  except
    on E: Exception do
    begin
      raise EDJFormatError.Create
        ('Invalid DateTime format was provided. Expected an ISO 8601 ' +
        'formatted string.', context);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTDate(value: TJSONValue; dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
const
  format = 'yyyy-mm-dd';
var
  jStr: TJSONString;
  str: string;
  dt: TDate;
  fmt: TFormatSettings;
begin

  if not(value is TJSONString) then
  begin
    raise EDJError.Create('Expected a JSON string in date format.', context);
  end;
  jStr := value as TJSONString;
  str := jStr.value;
  try
    fmt := TFormatSettings.Create('en-US');
    fmt.LongDateFormat := format;
    fmt.ShortDateFormat := format;
    fmt.DateSeparator := '-';
    dt := StrToDateTime(str, fmt);
  except
    on E: Exception do
    begin
      raise EDJFormatError.Create
        ('Invalid Date format was provided. Expected an "' + format +
        '" formatted string.', context);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTTime(value: TJSONValue; dataType: TRttiType; var objOut: TValue;
  context: TDerContext);
const
  format = 'hh:nn:ss.z';
var
  jStr: TJSONString;
  str: string;
  dt: TTime;
  fmt: TFormatSettings;
begin

  if not(value is TJSONString) then
  begin
    raise EDJError.Create('Expected a JSON string in time format.', context);
  end;
  jStr := value as TJSONString;
  str := jStr.value;
  try
    fmt := TFormatSettings.Create('en-US');
    fmt.LongTimeFormat := format;
    fmt.ShortTimeFormat := format;
    fmt.TimeSeparator := ':';
    dt := StrToDateTime(str, fmt);
  except
    on E: Exception do
    begin
      raise EDJFormatError.Create
        ('Invalid DateTime format was provided. Expected an "' + format +
        '" formatted string.', context);
    end;
  end;

  objOut := TValue.From(dt);
end;

procedure DerTJSONValue(value: TJSONValue; dataType: TRttiType;
  var objOut: TValue; context: TDerContext);
var
  output: TJSONValue;
begin
  output := value.Clone as TJSONValue;
  context.AddHeapObject(output);
  objOut := TValue.From(output);
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

    if tmp.Name.ToLower = 'tdate' then
    begin
      Result := true;
      DerTDate(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower = 'ttime' then
    begin
      Result := true;
      DerTTime(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower = 'tjsonvalue' then
    begin
      Result := true;
      DerTJSONValue(value, dataType, objOut, context);
      exit;
    end;

    if context.settings.TreatStringDictionaryAsObject and
      (tmp.Name.ToLower.StartsWith('tdictionary<system.string,', true) or
      tmp.Name.ToLower.StartsWith('tdictionary<string,', true)) then
    begin
      Result := true;
      DerTDictionaryStringKey(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tdictionary<', true) then
    begin
      Result := true;
      DerTDictionary(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tpair<', true) then
    begin
      Result := true;
      DerTPair(value, dataType, objOut, context);
      exit;
    end;

    if tmp.Name.ToLower.StartsWith('tenumerable<', true) then
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

  allowUnusedFields: Boolean;

  fieldsUsed: integer;
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
    raise EDJError.Create('Expected a JSON Object. ', context);
  end;
  jsonObject := value as TJSONObject;

  // handle a "standard" object and deserialize it
  allowUnusedFields := context.settings.AllowUnusedJSONFields;
  found := False;
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
        context);
    end;
  end;

  fieldsUsed := 0;
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
      raise EDJError.Create
        ('Invalid JSON field name: is null or whitespace. ', context);
    end;

    // check if the field name exists in the json structure

    JsonValue := jsonObject.GetValue(jsonFieldName);
    if required then
    begin
      // the field is required but was not found
      if JsonValue = nil then
      begin
        raise EDJRequiredError.Create('Value with name "' + jsonFieldName +
          '" missing in JSON data. ', context);
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

          // set the default value in the resulting object
          if isRecord then
          begin
            field.SetValue(objValue.GetReferenceToRawData, fieldValue);
          end
          else
          begin
            field.SetValue(objValue.AsObject, fieldValue);
          end;

        end;

        // we took care of this object (either by assigning a default value or by leaving it as it is)
        continue;
      end;
    end;

    // use the json value provided
    Inc(fieldsUsed);

    // check if null is a valid json value
    if JsonValue is TJSONNull then
    begin
      if not nillable then
      begin
        context.PushPath(jsonFieldName);
        raise EDJNilError.Create
          ('Field value must not be nil, but JSON was null for field with name "'
          + jsonFieldName + '". ', context);
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
            + jsonFieldName + '". ', context);
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
      if JsonValue is TJSONNull then
      begin
        // field is allowed to be null and is null, hence set it to the empty value
        fieldValue := TValue.Empty;
      end
      else
      begin
        // default deserialization
        fieldValue := DeserializeInternal(JsonValue, field.FieldType, context);
      end;
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

  // check if there were unused fields and if that is not allowed
  if not allowUnusedFields then
  begin
    if jsonObject.Count > fieldsUsed then
    begin
      raise EDJUnusedFieldsError.Create
        ('JSON object contains unused fields.', context);
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
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    if not(value is TJSONArray) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle = System.TypeInfo(Boolean) then
  begin
    if not(value is TJSONBool) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerBool(value as TJSONBool, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInteger then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkWString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkUString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkLString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch, context);
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
      raise EDJError.Create(typeMismatch, context);
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
      raise EDJError.Create('Record type can not be null. ', context);
    end;

    if not(value is TJSONObject) then
    begin
      raise EDJError.Create(typeMismatch, context);
    end;

    Result := DerObject(value as TJSONObject, dataType, context, true);

  end
  else
  begin
    raise EDJError.Create
      ('Type of field is not supported for deserialization. ', context);
  end;
end;

{ DelphiJSON<T> }

constructor DelphiJSON<T>.Create;
var
  tmp: TSerContext;
begin
  tmp := nil;
  raise EDJError.Create('Do not create instances of this object!', tmp);
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
    on E: EDJError do
    begin
      val.Free;
      raise E.Clone;
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
    on E: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise E.Clone;
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
    on E: EDJError do
    begin
      JsonValue.Free;
      raise E.Clone
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
    on E: EDJError do
    begin
      context.FreeAllHeapObjects;
      context.Free;
      createdSettings.Free;
      raise E.Clone
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

function TSerContext.FullPath: string;
begin
  Result := PathToString(path);
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
      raise Exception.Create('Invalid array index!');
    end;
    Result[i] := tmp;
    Inc(i);
  end;

end;

function TSerContext.IsTracked(obj: TObject): Boolean;
begin
  if obj = nil then
  begin
    Result := False;
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
    found := False;
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

function TSerContext.ToString: string;
begin
  Result := 'Context: { ' + FullPath + ' }';
end;

procedure TSerContext.Track(obj: TObject);
begin
  if obj = nil then
  begin
    exit;
  end;
  self.objectTracker.AddOrSetValue(obj, true);
end;

{ TDJSettings }

constructor TDJSettings.Default;
begin
  RequireSerializableAttributeForNonRTLClasses := true;
  DateTimeReturnUTC := true;
  IgnoreNonNillable := False;
  RequiredByDefault := true;
  TreatStringDictionaryAsObject := true;
  AllowUnusedJSONFields := true;
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

constructor EDJError.Create(errorMessage: String; const path: TList<String>);
begin
  inherited Create(errorMessage + ' - ' + PathToString(path));
  self.errorMessage := errorMessage;
  self.path := TList<String>.Create(path);
end;

constructor EDJError.Create(errorMessage: String; context: TSerContext);
begin
  if context <> nil then
  begin
    inherited Create(errorMessage + ' - ' + context.FullPath);
    self.errorMessage := errorMessage;
    self.path := TList<String>.Create(context.path);
  end
  else
  begin
    inherited Create(errorMessage);
    self.errorMessage := errorMessage;
    self.path := nil;
  end;
end;

destructor EDJError.Destroy;
begin
  self.path.Free;
  self.path := nil;
  inherited;
end;

function EDJError.FullPath: string;
begin
  Result := PathToString(path);
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

{ EDJRequiredError }

function EDJRequiredError.Clone: EDJError;
begin
  Result := EDJRequiredError.Create(self.errorMessage, self.path);
end;

{ EDJNilError }

function EDJNilError.Clone: EDJError;
begin
  Result := EDJNilError.Create(self.errorMessage, self.path);
end;

{ EDJWrongArraySizeError }

function EDJWrongArraySizeError.Clone: EDJError;
begin
  Result := EDJWrongArraySizeError.Create(self.errorMessage, self.path);
end;

{ EDJCycleError }

function EDJCycleError.Clone: EDJError;
begin
  Result := EDJCycleError.Create(self.errorMessage, self.path);
end;

{ EDJFormatError }

function EDJFormatError.Clone: EDJError;
begin
  Result := EDJFormatError.Create(self.errorMessage, self.path);
end;

{ DJNoUnusedJSONFieldsAttribute }

constructor DJNoUnusedJSONFieldsAttribute.Create(const noUnusedFields: Boolean);
begin
  self.noUnusedFields := noUnusedFields;
end;

{ EDJUnusedFieldsError }

function EDJUnusedFieldsError.Clone: EDJError;
begin
  Result := EDJUnusedFieldsError.Create(self.errorMessage, self.path);
end;

end.
