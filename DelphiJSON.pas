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
    destructor Destroy;

    function FullPath: string;
    procedure PushPath(val: string);
    procedure PopPath;

    function ToString: string;

  end;

function SerializeInternal(value: TValue; context: TSerContext): TJSONValue;

implementation

function SerArray(value: TValue; context: TSerContext): TJSONArray;
var
  size: integer;
  i: integer;
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
  i: integer;
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

end;

function SerTPair(data: TObject; dataType: TRttiType; context: TSerContext)
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

  keyValue := keyField.GetValue(data);
  valueValue := valueField.GetValue(data);

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

function SerHandledSpecialCase(data: TObject; dataType: TRttiType;
  var output: TJSONValue; context: TSerContext): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.StartsWith('TDictionary<string,', true) then
    begin
      Result := true;
      output := SerTDictionaryStringKey(data, dataType, context);
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
      output := SerTEnumerable(data, dataType, context);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := False;
end;

function SerObject(value: TValue; context: TSerContext): TJSONValue;
var
  data: TObject;
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

  data := value.AsObject;

  dataType := context.RTTI.GetType(data.ClassInfo);

  // checking if a special case handled the type of data
  if SerHandledSpecialCase(data, dataType, Result, context) then
  begin
    exit;
  end;

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
    fieldValue := field.GetValue(data);

    context.PushPath(jsonFieldName);
    serializedField := SerializeInternal(fieldValue, context);
    context.PopPath;

    // add the variable to the resulting object
    resultObject.AddPair(jsonFieldName, serializedField);

  end;

end;

function SerializeInternal(value: TValue; context: TSerContext): TJSONValue;
begin
  // check for the type and call the appropriate subroutine for serialization

  // TODO: special handling for TDateTime and other cases

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
    Result := SerObject(value, context);
  end
  else
  begin
    raise EDJError.Create('Type not supported for serialization. ' +
      context.ToString);
  end;
end;

function DeserializeInternal(value: TJSONValue; dataType: TRttiType): TValue;
begin

end;

{ DelphiJSON<T> }

constructor DelphiJSON<T>.Create;
begin
  raise EDJError.Create('Do not create instances of this object!');
end;

class function DelphiJSON<T>.Deserialize(data: String): T;
begin
  // TODO: implement
end;

class function DelphiJSON<T>.DeserializeJ(data: TJSONValue): T;
begin
  // TODO: implement
end;

class function DelphiJSON<T>.Serialize(data: T): string;
var
  jsonValue: TJSONValue;
begin
  jsonValue := SerializeJ(data);
  Result := jsonValue.ToJSON;
  jsonValue.Free;
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

procedure TSerContext.PushPath(val: string);
begin
  path.Push(val);
end;

function TSerContext.ToString: string;
begin
  Result := 'Context: { ' + FullPath + ' }';
end;

end.
