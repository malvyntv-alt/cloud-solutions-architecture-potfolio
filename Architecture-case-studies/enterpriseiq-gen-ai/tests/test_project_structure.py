from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def test_environment_roots():
    assert all((ROOT / f"terraform/environments/{e}/main.tf").exists() for e in ("dev", "prod"))
def test_buildspecs():
    assert (ROOT / "cicd/buildspec-plan.yml").exists()
    assert (ROOT / "cicd/buildspec-apply.yml").exists()

def test_standard_network_mode_and_no_vpc_resources():
    for env in ("dev", "prod"):
        tfvars = (ROOT / f"terraform/environments/{env}/terraform.tfvars").read_text()
        assert 'network_mode = "standard"' in tfvars
    source = "\n".join(p.read_text() for p in (ROOT / "terraform").rglob("*.tf"))
    for resource_type in ("aws_vpc", "aws_subnet", "aws_nat_gateway", "aws_internet_gateway", "aws_vpc_endpoint"):
        assert f'resource "{resource_type}"' not in source
