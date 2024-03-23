# Eisvogel

[Eisvogel](https://github.com/Wandmalfarbe/pandoc-latex-template) is a clean pandoc LaTeX template for lecture notes. It is specifically designed for students of the lecture "Algorithms and Data Structures" at Karlsruhe Institute of Technology (KIT). However, it is quite generic and can be used for other lecture notes as well.

## Example

Add a code block at the start of your markdown file to include the template:

```yaml
---
title: "Board Environment Setup"
author: [Yongxi Yang]
date: "2024-03-22"
subject: "Markdown"
keywords: [Markdown, Tutorial, Board]
listings-disable-line-numbers: true
fontfamily: xeCJK
...
```

```bash
alias pandock='docker run --rm -v `pwd`:/data alwaysproblem/pandoc/extra'
pandock board_env_setup.md -o example.pdf --template eisvogel --listings --from markdown --pdf-engine=xelatex
```
