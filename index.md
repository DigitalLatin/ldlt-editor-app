---
layout: null
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    {% assign edition_url = "/editions/" | append: site.data.edition.slug | append: "/" %}
    <meta http-equiv="refresh"
          content="0; url={{ edition_url | relative_url }}">
    <title>LDLT Edition Preview</title>
</head>
<body>
    <p>
        <a href="{{ edition_url | relative_url }}">
            Open the edition
        </a>
    </p>
</body>
</html>