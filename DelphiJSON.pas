unit DelphiJSON;

interface

uses
  System.SysUtils, System.JSON, System.RTTI;

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
  JSONValueAttribute = class(TCustomAttribute)
  public
    Name: string;
    constructor Create(const Name: string);
  end;

  JSONSerializableAttribute = class(TCustomAttribute)

  end;

  EJSONError = class(Exception);

function SerializeInternal(value: TValue): TJSONValue;

implementation

function SerArray(value: TValue): TJSONArray;
var
  size: integer;
  i: integer;
begin
  Result := TJSONArray.Create;
  size := value.GetArrayLength;
  for i := 0 to size - 1 do
  begin
    Result.AddElement(SerializeInternal(value.GetArrayElement(i)));
  end;
end;

function SerFloat(value: TValue): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsType<Single>());
end;

function SerInt64(value: TValue): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInt64);
end;

function SerInt(value: TValue): TJSONNumber;
begin
  Result := TJSONNumber.Create(value.AsInteger);
end;

function SerString(value: TValue): TJSONString;
begin
  Result := TJSONString.Create(value.AsString);
end;

function SerTEnumerable(data: TObject; dataType: TRttiType): TJSONArray;
var
  getEnumerator: TRttiMethod;
  enumerator: TValue;
  moveNext: TRttiMethod;
  currentProperty: TRttiProperty;
  currentValue: TValue;
  currentSerialized: TJSONValue;
  moveNextValue: TValue;
  moveNextResult: Boolean;
begin
  // idea: fetch enumerator with rtti, enumerate using movenext, adding objects
  // to the array

  getEnumerator := dataType.GetMethod('GetEnumerator');
  getEnumerator.Invoke(data, enumerator);

  moveNext := getEnumerator.ReturnType.GetMethod('MoveNext');
  currentProperty := getEnumerator.ReturnType.GetProperty('Current');

  Result := TJSONArray.Create;

  repeat
    // retrieve current object
    currentValue := currentProperty.GetValue(enumerator);

    // serialize it and add it to the result
    currentSerialized := SerializeInternal(currentValue);
    Result.AddElement(currentSerialized);

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator);
    moveNextResult := moveNextValue.AsBoolean;
  until not moveNextResult;

end;

function SerTDictionaryStringKey(data: TObject; dataType: TRttiType)
  : TJSONObject;
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
  getEnumerator.Invoke(data, enumerator);

  moveNext := getEnumerator.ReturnType.GetMethod('MoveNext');
  currentProperty := getEnumerator.ReturnType.GetProperty('Current');

  keyField := currentProperty.PropertyType.GetField('Key');
  valueField := currentProperty.PropertyType.GetField('Value');

  Result := TJSONObject.Create;

  repeat
    // retrieve current pair
    currentPairValue := currentProperty.GetValue(enumerator);

    keyValue := keyField.GetValue(currentPairValue.AsObject);
    valueValue := valueField.GetValue(currentPairValue.AsObject);

    keyString := keyValue.AsString;

    serializedValue := SerializeInternal(valueValue);
    Result.AddPair(keyString, serializedValue);

    // move to the next object
    moveNextValue := moveNext.Invoke(enumerator);
    moveNextResult := moveNextValue.AsBoolean;
  until not moveNextResult;

end;

function SerTPair(data: TObject; dataType: TRttiType): TJSONObject;
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

  serializedKey := SerializeInternal(keyValue);
  serializedValue := SerializeInternal(valueValue);

  Result := TJSONObject.Create;
  Result.AddPair('key', serializedKey);
  Result.AddPair('value', serializedValue);

end;

function SerHandledSpecialCase(data: TObject; dataType: TRttiType;
  var output: TJSONValue): Boolean;
var
  tmp: TRttiType;
begin
  tmp := dataType;
  while tmp <> nil do
  begin
    if tmp.Name.StartsWith('TDictionary<string,', true) then
    begin
      Result := true;
      output := SerTDictionaryStringKey(data, dataType);
      exit;
    end;

    if tmp.Name.StartsWith('TPair<', true) then
    begin
      Result := true;
      output := SerTPair(data, dataType);
      exit;
    end;

    if tmp.Name.StartsWith('TEnumerable<', true) then
    begin
      Result := true;
      output := SerTEnumerable(data, dataType);
      exit;
    end;

    tmp := tmp.BaseType;
  end;

  Result := False;
end;

function SerObject(value: TValue): TJSONValue;
var
  data: TObject;
  context: TRttiContext;
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

  // TODO: ideally create one context per serialization
  context := TRttiContext.Create;
  dataType := context.GetType(data.ClassInfo);

  // checking if a special case handled the type of data
  if SerHandledSpecialCase(data, dataType, Result) then
  begin
    context.Free;
    exit;
  end;

  // TODO: split this function in smaller parts

  // handle a "standard" object and serialize it

  // Ensure the object has the serializable attribute. (Fields added later)
  found := False;
  for attribute in dataType.GetAttributes() do
  begin
    if attribute is JSONSerializableAttribute then
    begin
      found := true;
      break;
    end;
  end;
  if not found then
  begin
    context.Free;
    raise EJSONError.Create
      ('Given object type is missing the JSONSerializable attribute');
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
      if attribute is JSONValueAttribute then
      begin
        found := true;
        jsonFieldName := (attribute as JSONValueAttribute).Name.Trim;
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
      context.Free;
      raise EJSONError.Create('Invalid JSON field name: is null or whitespace');
    end;

    // TODO: Add possibilities for converters here
    fieldValue := field.GetValue(data);
    serializedField := SerializeInternal(fieldValue);

    // add the variable to the resulting object
    resultObject.AddPair(jsonFieldName, serializedField);

  end;

  // free the context
  context.Free;

end;

function SerializeInternal(value: TValue): TJSONValue;
begin
  // check for the type and call the appropriate subroutine for serialization

  // TODO: special handling for TDateTime and other cases

  if value.IsArray then
  begin
    Result := SerArray(value);
  end
  else if value.Kind = TTypeKind.tkFloat then
  begin
    Result := SerFloat(value);
  end
  else if value.Kind = TTypeKind.tkInt64 then
  begin
    Result := SerInt64(value);
  end
  else if value.Kind = TTypeKind.tkInteger then
  begin
    Result := SerInt(value);
  end
  else if value.IsType<string>(False) then
  begin
    Result := SerString(value);
  end
  else if value.IsEmpty then
  begin
    Result := TJSONNull.Create;
  end
  else if value.IsObject then
  begin
    Result := SerObject(value);
  end
  else
  begin
    raise EJSONError.Create('Type not supported for serialization');
  end;
end;

{ DelphiJSON<T> }

constructor DelphiJSON<T>.Create;
begin
  raise EJSONError.Create('Do not create instances of this object!');
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
begin
  valueObject := TValue.From(data);
  Result := SerializeInternal(valueObject);
end;

{ JSONValueAttribute }

constructor JSONValueAttribute.Create(const Name: string);
begin
  self.Name := Name;
end;

end.
