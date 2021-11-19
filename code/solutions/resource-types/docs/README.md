# CfnWorkshop::EC2::KeyPair

Provides an EC2 key pair resource. A key pair is used to control login access to EC2 instances. This resource requires an existing user-supplied key pair.

## Syntax

To declare this entity in your AWS CloudFormation template, use the following syntax:

### JSON

<pre>
{
    "Type" : "CfnWorkshop::EC2::KeyPair",
    "Properties" : {
        "<a href="#keyname" title="KeyName">KeyName</a>" : <i>String</i>,
        "<a href="#publickey" title="PublicKey">PublicKey</a>" : <i>String</i>,
    }
}
</pre>

### YAML

<pre>
Type: CfnWorkshop::EC2::KeyPair
Properties:
    <a href="#keyname" title="KeyName">KeyName</a>: <i>String</i>
    <a href="#publickey" title="PublicKey">PublicKey</a>: <i>String</i>
</pre>

## Properties

#### KeyName

The name for the key pair.

_Required_: Yes

_Type_: String

_Minimum_: <code>1</code>

_Maximum_: <code>255</code>

_Pattern_: <code>^[a-zA-Z0-9_-]+$</code>

_Update requires_: [Replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement)

#### PublicKey

The public key material.

_Required_: Yes

_Type_: String

_Update requires_: [Replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement)

## Return Values

### Ref

When you pass the logical ID of this resource to the intrinsic `Ref` function, Ref returns the KeyName.

### Fn::GetAtt

The `Fn::GetAtt` intrinsic function returns a value for a specified attribute of this type. The following are the available attributes and sample return values.

For more information about using the `Fn::GetAtt` intrinsic function, see [Fn::GetAtt](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html).

#### Fingerprint

The MD5 public key fingerprint as specified in section 4 of RFC 4716.
