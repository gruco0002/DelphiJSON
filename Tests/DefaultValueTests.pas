unit DefaultValueTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  [DJSerializable]
  TTestClass = class
  public

    [DJValue('str')]
    [DJRequired(false)]
    [DJDefaultValue('Hello World')]
    str: String;

    [DJValue('b')]
    [DJRequired(false)]
    [DJDefaultValue(true)]
    b: Boolean;

    [DJValue('i')]
    [DJRequired(false)]
    [DJDefaultValue(156)]
    i: Integer;

    [DJValue('s')]
    [DJRequired(false)]
    [DJDefaultValue(single(0.56))]
    s: Single;

  end;

  [TestFixture]
  TDefaultValueTests = class(TObject)
  public

    [Test]
    procedure Test1;

  end;

implementation

{ TDefaultValueTests }

procedure TDefaultValueTests.Test1;
const
  res = '{}';
var
  tmp: TTestClass;
begin
  tmp := DelphiJSON<TTestClass>.Deserialize(res);

  Assert.AreEqual('Hello World', tmp.str);
  Assert.AreEqual(true, tmp.b);
  Assert.AreEqual(156, tmp.i);
  Assert.AreEqual(single(0.56), tmp.s);

  tmp.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TDefaultValueTests);

end.
