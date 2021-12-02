unit ListTests;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, DelphiJSONAttributes;

type

  [DJSerializable]
  TCustom = class
  public
    [DJValue('list')]
    list: TList<Integer>;

  end;

  [TestFixture]
  TListTests = class(TObject)
  public

    [Test]
    procedure TestSerializationObj;

    [Test]
    procedure TestDeserializationObj;

    [Test]
    procedure TestSerialization;

    [Test]
    procedure TestDeserialization;

  end;

implementation

uses
  System.JSON, JSONComparer, DelphiJSON;

{ TListTests }

procedure TListTests.TestDeserialization;
const
  res = '[16, 12, 5, -8, 9]';
var
  desired: TList<Integer>;
  result: TList<Integer>;
  i: Integer;
begin
  desired := TList<Integer>.Create;
  desired.Add(16);
  desired.Add(12);
  desired.Add(5);
  desired.Add(-8);
  desired.Add(9);

  result := DelphiJSON < TList < Integer >>.Deserialize(res);
  Assert.IsNotNull(result);
  Assert.AreEqual(desired.Count, result.Count);

  for i := 0 to desired.Count - 1 do
  begin
    Assert.AreEqual(desired[i], result[i]);
  end;

  desired.Free;
  result.Free;

end;

procedure TListTests.TestDeserializationObj;
const
  res = '{"list":[16, 12, 5, -8, 9]}';
var
  desired: TList<Integer>;
  result: TCustom;
  i: Integer;
begin
  desired := TList<Integer>.Create;
  desired.Add(16);
  desired.Add(12);
  desired.Add(5);
  desired.Add(-8);
  desired.Add(9);

  result := DelphiJSON<TCustom>.Deserialize(res);
  Assert.IsNotNull(result);
  Assert.IsNotNull(result.list);
  Assert.AreEqual(desired.Count, result.list.Count);

  for i := 0 to desired.Count - 1 do
  begin
    Assert.AreEqual(desired[i], result.list[i]);
  end;

  desired.Free;
  result.list.Free;
  result.Free;

end;

procedure TListTests.TestSerialization;
var
  res: TList<Integer>;
  desired: TJSONArray;
  serialized: TJSONValue;
begin
  res := TList<Integer>.Create;
  res.Add(16);
  res.Add(12);
  res.Add(5);
  res.Add(-8);
  res.Add(9);

  desired := TJSONArray.Create;
  desired.Add(16);
  desired.Add(12);
  desired.Add(5);
  desired.Add(-8);
  desired.Add(9);

  serialized := DelphiJSON < TList < Integer >>.SerializeJ(res);
  Assert.IsNotNull(serialized);
  Assert.IsTrue(JSONEquals(desired, serialized));

  serialized.Free;
  desired.Free;
  res.Free;

end;

procedure TListTests.TestSerializationObj;
const
  JSON = '{"list":[16, 12, 5, -8, 9]}';
var
  res: TCustom;
  custom: TCustom;
  desired: TJSONValue;
  serialized: TJSONValue;
begin
  res := TCustom.Create;
  res.list := TList<Integer>.Create;
  res.list.Add(16);
  res.list.Add(12);
  res.list.Add(5);
  res.list.Add(-8);
  res.list.Add(9);

  desired := TJSONObject.ParseJSONValue(JSON);

  serialized := DelphiJSON<TCustom>.SerializeJ(res);
  Assert.IsNotNull(serialized);
  Assert.IsTrue(JSONEquals(desired, serialized));

  serialized.Free;
  desired.Free;
  res.list.Free;
  res.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TListTests);

end.
