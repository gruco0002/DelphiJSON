unit JSONComparer;

interface

uses System.JSON;

function JSONEquals(value1: TJSONValue; value2: TJSONValue;
  strictArrayOrder: Boolean = true): Boolean;

implementation

uses
  System.Generics.Collections;

function CmpObject(value1: TJSONObject; value2: TJSONObject;
  strictArrayOrder: Boolean): Boolean;
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

    val := value2.GetValue(p.JsonString.Value);
    if val = nil then
    begin
      Result := false;
      exit;
    end;

    if not JSONEquals(p.JsonValue, val, strictArrayOrder) then
    begin
      Result := false;
      exit;
    end;

  end;

  Result := true;

end;

function CmpArray(value1: TJSONArray; value2: TJSONArray;
  strictArrayOrder: Boolean): Boolean;
var
  i: integer;
begin
  if value1.Count <> value2.Count then
  begin
    Result := false;
    exit;
  end;

  for i := 0 to value1.Count - 1 do
  begin
    if not JSONEquals(value1.Items[i], value2.Items[i], strictArrayOrder) then
    begin
      Result := false;
      exit;
    end;
  end;

  Result := true;
end;

function CmpArrayInvariantOrder(value1: TJSONArray; value2: TJSONArray;
  strictArrayOrder: Boolean): Boolean;
var
  i: integer;
  j: integer;
  used: TList<Boolean>;
  found: Boolean;
begin
  if value1.Count <> value2.Count then
  begin
    Result := false;
    exit;
  end;

  used := TList<Boolean>.Create;
  for i := 0 to value2.Count - 1 do
  begin
    used.Add(false);
  end;

  for i := 0 to value1.Count - 1 do
  begin
    found := false;
    for j := 0 to value2.Count - 1 do
    begin
      if JSONEquals(value1.Items[i], value2.Items[j], strictArrayOrder) and
        (not used[j]) then
      begin
        used[j] := true;
        found := true;
        break;
      end;
    end;

    if not found then
    begin
      Result := false;
      used.Free;

      exit;
    end;

  end;

  used.Free;

  Result := true;
end;

function JSONEquals(value1: TJSONValue; value2: TJSONValue;
  strictArrayOrder: Boolean): Boolean;
begin
  Result := false;

  if (value1 is TJSONObject) and (value2 is TJSONObject) then
  begin
    Result := CmpObject(value1 as TJSONObject, value2 as TJSONObject,
      strictArrayOrder);
  end
  else if (value1 is TJSONArray) and (value2 is TJSONArray) then
  begin
    if strictArrayOrder then
    begin
      Result := CmpArray(value1 as TJSONArray, value2 as TJSONArray,
        strictArrayOrder);
    end
    else
    begin
      Result := CmpArrayInvariantOrder(value1 as TJSONArray,
        value2 as TJSONArray, strictArrayOrder);
    end;
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
