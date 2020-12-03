unit JSONValueTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TJSONValueTests = class(TObject)
  public

    [Test]
    procedure TestSer;

    [Test]
    procedure TestDer;

  end;

implementation

uses
  System.JSON, System.Generics.Collections, DelphiJSON, JSONComparer;

{ TJSONValueTests }

procedure TJSONValueTests.TestDer;
const
  data = '["abc", 123, false, 14.5, { "hello": "world" }]';
var
  res: TList<TJSONValue>;
  i: Integer;
begin
  res := DelphiJSON < TList < TJSONValue >>.Deserialize(data);
  Assert.IsNotNull(res);
  Assert.AreEqual(5, res.Count);

  for i := 0 to res.Count - 1 do
  begin
    Assert.IsNotNull(res[i]);
  end;
  Assert.IsNotNull(res[0] as TJSONString);
  Assert.IsNotNull(res[1] as TJSONNumber);
  Assert.IsNotNull(res[2] as TJSONBool);
  Assert.IsNotNull(res[3] as TJSONNumber);
  Assert.IsNotNull(res[4] as TJSONObject);

  Assert.AreEqual('abc', (res[0] as TJSONString).Value);
  Assert.AreEqual(123, (res[1] as TJSONNumber).AsInt);
  Assert.AreEqual(false, (res[2] as TJSONBool).AsBoolean);
  Assert.AreEqual(double(14.5), (res[3] as TJSONNumber).AsDouble);

  Assert.IsNotNull((res[4] as TJSONObject).GetValue('hello'));
  Assert.AreEqual('world', (res[4] as TJSONObject).GetValue('hello').Value);

  for i := 0 to res.Count - 1 do
  begin
    res[i].Free;
  end;
  res.Free;

end;

procedure TJSONValueTests.TestSer;
const
  data = '["Hello World", true, 42]';
type
  tjarr = array of TJSONValue;
var
  ls: tjarr;
  ser: TJSONValue;
  tmp: TJSONValue;
begin
  SetLength(ls, 3);
  ls[0] := TJSONString.Create('Hello World');
  ls[1] := TJSONBool.Create(true);
  ls[2] := TJSONNumber.Create(42);

  ser := DelphiJSON<tjarr>.SerializeJ(ls);
  tmp := TJSONObject.ParseJSONValue(data);

  Assert.IsTrue(JSONEquals(ser, tmp));

  tmp.Free;
  ser.Free;
  ls[0].Free;
  ls[1].Free;
  ls[2].Free;

end;

initialization

TDUnitX.RegisterTestFixture(TJSONValueTests);

end.
