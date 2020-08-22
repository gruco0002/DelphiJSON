unit DelphiJSON;

interface

uses
  System.SysUtils, System.JSON, System.RTTI, System.Generics.Collections;

type
  DelphiJSON<T> = class

  public
    class function Deserialize(data: String): T;
    class function DeserializeJ(data: TJSONValue): T;
    class function Serialize(data: T): string;
    class function SerializeJ(data: T): TJSONValue;

  private
    constructor Create;

  end;

  /// This attribute allows a field or property to be serialized / deserialized.
  DJValueAttribute = class(TCustomAttribute)
  public
    Name: string;
    constructor Create(const Name: string);
  end;

  DJSerializableAttribute = class(TCustomAttribute)

  end;

  EDJError = class(Exception);

  TSerContext = class
  private
    path: TStack<string>;
  public
    RTTI: TRttiContext;

    constructor Create;
    destructor Destroy; override;

    function FullPath: string;
    procedure PushPath(val: string); overload;
    procedure PushPath(index: Integer); overload;
    procedure PopPath;

    function ToString: string;

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
  size: Integer;
  i: Integer;
begin
  Result := TJSONArray.Create;
  size := value.GetArrayLength;
  for i := 0 to size - 1 do
  begin
    context.PushPath(i.ToString);
    Result.AddElement(SerializeInternal(value.GetArrayElement(i), context));
    context.PopPath;
  end;
end;

function SerFloat(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsType<Single>());
end;

function SerInt64(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInt64);
end;

function SerInt(value: TValue; context: TSerContext): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInteger);
end;

function SerString(value: TValue; context: TSerContext): TJSONString;
begin
  Result := TJSONString.Create(value.AsString);
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
  i: Integer;
begin
  // idea: fetch enumerator with rtti, enumerate using movenext, adding objects
  // to the array

  getEnumerator := dataType.GetMethod('GetEnumerator');
  enumerator := getEnumerator.Invoke(data, []);

  moveNext := getEnumerator.ReturnType.GetMethod('MoveNext');
  currentProperty := getEnumerator.ReturnType.GetProperty('Current');

  Result := TJSONArray.Create;

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
  Result.AddPair('key', serializedKey);
  Result.AddPair('value', serializedValue);

end;

function SerTDateTime(data: TValue; dataType: TRttiType; context: TSerContext)
  : TJSONString;
var
  dt: TDateTime;
  str: string;
begin
  dt := data.AsType<TDateTime>();
  // TODO: add sth to handle timezones (and perhaps a setting in the context?)
  str := DateToISO8601(dt);
  Result := TJSONString.Create(str);
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
  tmp: TJSONValue;
begin

  dataType := context.RTTI.GetType(value.TypeInfo);

  // TODO: split this function in smaller parts

  // handle a "standard" object and serialize it

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
      ('Given object type is missing the JSONSerializable attribute. ' +
      context.ToString);
  end;

  // Init the result object
  resultObject := TJSONObject.Create;
  Result := resultObject;

  // adding fields to the object
  objectFields := dataType.GetFields;
  for field in objectFields do
  begin
    // check for the jsonValue parameter
    found := False;
    for attribute in field.GetAttributes() do
    begin
      if attribute is DJValueAttribute then
      begin
        found := true;
        jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
        break;
      end;
    end;

    if not found then
    begin
      // skip this field since it is not opted-in for serialization
      continue;
    end;

    // check if the field name is valid
    if string.IsNullOrWhiteSpace(jsonFieldName) then
    begin
      raise EDJError.Create('Invalid JSON field name: is null or whitespace. ' +
        context.ToString);
    end;

    // TODO: Add possibilities for converters here

    if isRecord then
    begin
      fieldValue := field.GetValue(value.GetReferenceToRawData);
    end
    else
    begin
      fieldValue := field.GetValue(value.AsObject);
    end;

    context.PushPath(jsonFieldName);
    serializedField := SerializeInternal(fieldValue, context);
    context.PopPath;

    // add the variable to the resulting object
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
  end
  else if value.IsType<Boolean> then
  begin
    Result := TJSONBool.Create(value.AsBoolean);
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
    raise EDJError.Create('Type not supported for serialization. ' +
      context.ToString);
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
  counter: Integer;

  BaseType: TRttiType;

  params: TArray<TValue>;
begin
  objType := dataType.AsInstance;

  // TODO: find correct constructor (since create is not always supported with no arguments)
  // idea: Iterate over all constructors of the instance and choose a fitting one by the following priority:
  // 1. one tagged with an (yet to introduce) attribute
  // 2. Create (if it does not need any arguments)
  // 3. Error Message
  // an alternative to that would be a way to create the object without the use of a constructor (if this is possible)

  selectedMethod := nil;

  SetLength(params, 0);

  for method in objType.GetMethods do
  begin

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

    if not(method.Visibility in [TMemberVisibility.mvPublished,
      TMemberVisibility.mvPublic]) then
    begin
      continue;
    end;

    counter := 0;
    for tmp in method.GetParameters do
    begin
      // TODO: check if a default value is set
      Inc(counter);
    end;
    if counter <> 0 then
    begin
      continue;
    end;

    if method.Name.ToLower <> 'create' then
    begin
      continue;
    end;

    if selectedMethod <> nil then
    begin
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
    end
    else
    begin
      selectedMethod := method;
    end;

  end;

  if selectedMethod = nil then
  begin
    raise EDJError.Create('Did not find a suitable constructor for type. ' +
      context.ToString);
  end;

  Result := selectedMethod.Invoke(objType.MetaclassType, params);

end;

function DerArray(value: TJSONArray; dataType: TRttiType;
  context: TDerContext): TValue;
var
  res: array of TValue;
  valueType: TRttiType;
  i: Integer;
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
        ('Element count of the given JSON array does not match the size of a static array. '
        + context.ToString);
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
  valFloat: Double;
  valInt64: Int64;
  valInt: Integer;
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
  typeKey: TRttiType;
  valueValue: TValue;
  typeValue: TRttiType;

  i: Integer;

begin
  if not(value is TJSONObject) then
  begin
    raise EDJError.Create('Expected a JSON object. ' + context.ToString);
  end;
  jsonObject := value as TJSONObject;

  // create object
  objOut := DerConstructObject(dataType, context);

  // get the method that we will use to add into the dictionary
  addMethod := dataType.GetMethod('AddOrSetValue');

  // get the types of the key and value
  typeKey := addMethod.GetParameters[0].ParamType; // this should be a string
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

  i: Integer;
begin
  if not(value is TJSONArray) then
  begin
    raise EDJError.Create('Expected a JSON array. ' + context.ToString);
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
      raise EDJError.Create('Expected a JSON object. ' + context.ToString);
    end;
    jArrObject := jArrValue as TJSONObject;

    jsonKey := jArrObject.GetValue('key');
    if jsonKey = nil then
    begin
      raise EDJError.Create('Expected a field with name "key". ' +
        context.ToString);
    end;

    JsonValue := jArrObject.GetValue('value');
    if jsonKey = nil then
    begin
      raise EDJError.Create('Expected a field with name "value". ' +
        context.ToString);
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
    raise EDJError.Create('Expected a JSON object. ' + context.ToString);
  end;
  jsonObject := value as TJSONObject;

  jsonKey := jsonObject.GetValue('key');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "key". ' +
      context.ToString);
  end;

  JsonValue := jsonObject.GetValue('value');
  if jsonKey = nil then
  begin
    raise EDJError.Create('Expected a field with name "value". ' +
      context.ToString);
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
  i: Integer;
  elementValue: TValue;

begin
  if not(value is TJSONArray) then
  begin
    raise EDJError.Create('Expected a JSON array. ' + context.ToString);
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
    raise EDJError.Create('Could not find a method to add items to the object. '
      + context.ToString);
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
    raise EDJError.Create('Expected a JSON string in date time format. ' +
      context.ToString);
  end;
  jStr := value as TJSONString;
  str := value.value;

  // TODO: add sth to handle timezones (and perhaps a setting in the context?)
  dt := ISO8601ToDate(str);
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
    raise EDJError.Create('Expected a JSON Object. ' + context.ToString);
  end;
  jsonObject := value as TJSONObject;

  // handle a "standard" object and deserialize it

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
      ('Given object type is missing the JSONSerializable attribute. ' +
      context.ToString);
  end;

  // getting fields from the object
  objectFields := dataType.GetFields;
  for field in objectFields do
  begin
    // check for the jsonValue parameter
    found := False;
    for attribute in field.GetAttributes() do
    begin
      if attribute is DJValueAttribute then
      begin
        found := true;
        jsonFieldName := (attribute as DJValueAttribute).Name.Trim;
        break;
      end;
    end;

    if not found then
    begin
      // skip this field since it is not opted-in for serialization
      continue;
    end;

    // check if the field name is valid
    if string.IsNullOrWhiteSpace(jsonFieldName) then
    begin
      raise EDJError.Create('Invalid JSON field name: is null or whitespace. ' +
        context.ToString);
    end;

    // check if the field name exists in the json structure

    JsonValue := jsonObject.GetValue(jsonFieldName);
    if JsonValue = nil then
    begin
      raise EDJError.Create('Value with name "' + jsonFieldName +
        '" missing in JSON data. ' + context.ToString);
    end;

    // TODO: Add possibilities for converters here

    context.PushPath(jsonFieldName);
    fieldValue := DeserializeInternal(JsonValue, field.FieldType, context);
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
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkDynArray then
  begin
    if not(value is TJSONArray) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerArray(value as TJSONArray, dataType, context);
  end
  else if dataType.Handle = System.TypeInfo(Boolean) then
  begin
    if not(value is TJSONBool) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerBool(value as TJSONBool, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInt64 then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkInteger then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkFloat then
  begin
    if not(value is TJSONNumber) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerNumber(value as TJSONNumber, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkWString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkUString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;
    Result := DerString(value as TJSONString, dataType, context);
  end
  else if dataType.Handle^.Kind = TTypeKind.tkLString then
  begin
    if not(value is TJSONString) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
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
      raise EDJError.Create(typeMismatch + context.ToString);
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
      raise EDJError.Create('Record type can not be null. ' + context.ToString);
    end;

    if not(value is TJSONObject) then
    begin
      raise EDJError.Create(typeMismatch + context.ToString);
    end;

    Result := DerObject(value as TJSONObject, dataType, context, true);

  end
  else
  begin
    raise EDJError.Create('Type of field is not supported for deserialization. '
      + context.ToString);
  end;
end;

{ DelphiJSON<T> }

constructor DelphiJSON<T>.Create;
begin
  raise EDJError.Create('Do not create instances of this object!');
end;

class function DelphiJSON<T>.Deserialize(data: String): T;
var
  val: TJSONValue;
begin
  val := TJSONObject.ParseJSONValue(data, true, true);
  Result := DeserializeJ(val);
  val.Free;
end;

class function DelphiJSON<T>.DeserializeJ(data: TJSONValue): T;
var
  context: TDerContext;
  rttiType: TRttiType;
  res: TValue;
begin
  context := TDerContext.Create;
  rttiType := context.RTTI.GetType(System.TypeInfo(T));
  res := DeserializeInternal(data, rttiType, context);
  context.Free;
  Result := res.AsType<T>();
end;

class function DelphiJSON<T>.Serialize(data: T): string;
var
  JsonValue: TJSONValue;
begin
  JsonValue := SerializeJ(data);
  Result := JsonValue.ToJSON;
  JsonValue.Free;
end;

class function DelphiJSON<T>.SerializeJ(data: T): TJSONValue;
var
  valueObject: TValue;
  context: TSerContext;
begin
  context := TSerContext.Create;
  valueObject := TValue.From<T>(data);
  Result := SerializeInternal(valueObject, context);
  context.Free;
end;

{ DJValueAttribute }

constructor DJValueAttribute.Create(const Name: string);
begin
  self.Name := Name;
end;

{ TSerContext }

constructor TSerContext.Create;
begin
  self.path := TStack<string>.Create;
  self.RTTI := TRttiContext.Create;
end;

destructor TSerContext.Destroy;
begin
  self.path.Free;
  self.RTTI.Free;
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

procedure TSerContext.PushPath(index: Integer);
begin
  path.Push(index.ToString);
end;

procedure TSerContext.PushPath(val: string);
begin
  path.Push(val);
end;

function TSerContext.ToString: string;
begin
  Result := 'Context: { ' + FullPath + ' }';
end;

end.
