unit EnumerableTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TEnumerableTests = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestList;

  end;

implementation

uses
  JSONComparer, DelphiJSON, System.JSON, System.Generics.Collections;

type

  [DJSerializable]
  TTest = class

  [DJValue('field')]
    field: integer;

    [DJValue('intList')]
    list: TList<integer>;

  end;

procedure TEnumerableTests.Setup;
begin
end;

procedure TEnumerableTests.TearDown;
begin
end;

procedure TEnumerableTests.TestList;
const
  res = '{"field":123, "intList":[12, 13, 42]}';
var
  tmp: TTest;
  ser: TJSONValue;
  desired: TJSONValue;
  s: string;
begin

  desired := TJSONObject.ParseJSONValue(res, false, True);

  tmp := TTest.Create;
  tmp.field := 123;
  tmp.list := TList<integer>.Create;
  tmp.list.Add(12);
  tmp.list.Add(13);
  tmp.list.Add(42);

  ser := DelphiJSON<TTest>.SerializeJ(tmp);

  s := ser.ToJSON;

  tmp.Free;

  Assert.IsTrue(JSONEquals(ser, desired));

  desired.Free;
  ser.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TEnumerableTests);

end.
