---
title: "Template Anatomy"
date: 2019-10-28T11:11:22Z
weight: 100
---

A template is a JSON or YAML formatted text file that describes your AWS infrastructure. The following example 
shows an AWS CloudFormation YAML template structure and its sections.

```yaml
  AWSTemplateFormatVersion: 'version date' (optional)

  Description: 'String' (optional)
    
  Metadata: 'template metadata' (optional)   
    
  Parameters: 'set of parameters' (optional)
      
  Mappings: 'set of mappings' (optional)

  Conditions: 'set of conditions' (optional)     
    
  Transform: 'set of transforms' (optional) 
    
  Resources: 'set of resources' (required)     
    
  Outputs: 'set of outputs' (optional)
```

Templates include several major sections. The **Resources** section is the only **required** section. Some sections in a 
template can be in any order. However, as you build your template, it can be helpful to use the logical order shown in 
the following lab because values in one section might refer to values from a previous section.
