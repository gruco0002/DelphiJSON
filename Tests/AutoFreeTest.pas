unit AutoFreeTest;

interface

uses
  DUnitX.TestFramework, DelphiJSONAttributes;

type

  [DJSerializable]
  TTest = class
  public

    [DJValue('ref')]
    [DJNonNilable]
    ref: TTest;

    destructor Destroy; override;

  end;

  [TestFixture]
  TAutoFreeTest = class(TObject)
  public

    [Test]
    procedure TestAutoFree;

  end;

implementation

uses
  DelphiJSON, DelphiJSONTypes;

{ TTest }

destructor TTest.Destroy;
begin
  self.ref.Free;
  inherited;
end;

{ TAutoFreeTest }

procedure TAutoFreeTest.TestAutoFree;
const
  res = '{"ref": {"ref": {"ref": null}}}';
var
  Test: TTest;
begin
  Assert.WillRaise(
    procedure
    begin
      Test := DelphiJSON<TTest>.Deserialize(res);
    end, EDJNilError);
end;

initialization

TDUnitX.RegisterTestFixture(TAutoFreeTest);

end.
