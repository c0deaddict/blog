+++
date = "2015-09-27T16:15:02Z"
draft = false
title = "code example"

+++

## Code example

This is a test

  plain code

{{< highlight html >}}
<section id="main">
  <div>
    <h1 id="title">{{ .Title }}</h1>
    {{ range .Data.Pages }}
      {{ .Render "summary"}}
    {{ end }}
  </div>
</section>
{{< /highlight >}}

## Another section
- test
- a
- b
