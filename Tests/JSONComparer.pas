unit JSONComparer;

interface

uses System.JSON;

function JSONEquals(value1: TJSONValue; value2: TJSONValue): Boolean;

implementation

function CmpObject(value1: TJSONObject; value2: TJSONObject): Boolean;
var
  p: TJSONPair;
  val: TJSONValue;
  i: integer;
begin
  if value1.Count <> value2.Count then
  begin
    Result := false;
    exit;
  end;

  // check keys
  for i := 0 to value1.Count - 1 do
  begin
    p := value1.Pairs[i];

    val := nil;
    val := value2.GetValue(p.JsonString.Value);
    if val = nil then
    begin
      Result := false;
      exit;
    end;

    if not JSONEquals(p.JsonValue, val) then
    begin
      Result := false;
      exit;
    end;

  end;

  Result := true;

end;

function CmpArray(value1: TJSONArray; value2: TJSONArray): Boolean;
begin
  // TODO: implement
end;

function JSONEquals(value1: TJSONValue; value2: TJSONValue): Boolean;
begin
  Result := false;

  if (value1 is TJSONObject) and (value2 is TJSONObject) then
  begin
    Result := CmpObject(value1 as TJSONObject, value2 as TJSONObject);
  end
  else if (value1 is TJSONArray) and (value2 is TJSONArray) then
  begin
    Result := CmpArray(value1 as TJSONArray, value2 as TJSONArray);
  end
  else if (value1 is TJSONBool) and (value2 is TJSONBool) then
  begin
    Result := (value1 as TJSONBool).AsBoolean = (value2 as TJSONBool).AsBoolean;
  end
  else if (value1 is TJSONNumber) and (value2 is TJSONNumber) then
  begin
    Result := (value1 as TJSONNumber)
      .AsDouble = (value2 as TJSONNumber).AsDouble;
  end
  else if (value1 is TJSONString) and (value2 is TJSONString) then
  begin
    Result := (value1 as TJSONString).Value = (value2 as TJSONString).Value;
  end
  else if (value1 is TJSONNull) and (value2 is TJSONNull) then
  begin
    Result := true;
  end;

end;

end.
