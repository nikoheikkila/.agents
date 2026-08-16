---
name: generating-alt-text
description: Write screen-reader-compatible alt text for images to improve accessibility. Use this skill whenever the user asks for alt text, image descriptions for accessibility, or help making images accessible — including for blog posts, documentation, web pages, social media, presentations, or any HTML/Markdown content. Also use when the user shares an image and asks what to write for its alt attribute, when reviewing content for WCAG compliance, when auditing or rewriting existing alt text, or when writing accessible names for SVGs and icon elements. Trigger even if the user doesn't say "accessibility" explicitly — phrases like "describe this image for a screen reader," "caption for visually impaired users," or "what should I put in the alt field" all qualify.
---

Alt text is read aloud by screen readers in place of an image.
Good alt text serves the reader's understanding of the surrounding content: it's not a literal pixel description.
Context determines what matters: the same image might need a long description on one page, a short one on another,
and empty alt on a third.

## Step 1: Classify the Image

Before writing anything, decide which category the image falls into. The answer changes everything.

### Decorative Images

The image adds visual flavour but no information. A dividing flourish, a stock photo of a laptop on an article about typing,
a pattern behind a headline. Give it an empty alt attribute (`alt=""`) and write nothing inside it.
Screen readers will skip it, which is the point. Do not write "decorative image", which is worse
than nothing, because it makes the reader stop for no payoff. Never drop the `alt` attribute altogether:
a missing attribute makes many screen readers fall back to announcing the file name.

### Informative Images

The image conveys content the reader needs: a product photo in a listing, a graph of results, a diagram of a workflow,
a photo illustrating a news story. Describe what the reader would miss without it, not what it looks like.

### Functional Images

The image _is_ the interactive element: a magnifying glass icon for search, a logo that links home, a trashcan icon on
a delete button. Describe the **action or destination**, not the icon.
For example, "Search" not "magnifying glass.", or "Home" not "company logo."

### Complex Images

Charts, infographics, detailed diagrams, data visualizations, maps with many labels. A short alt text can't carry it all.
Write a brief summary alt (the takeaway) and reference or provide a longer description nearby:
a caption, adjacent paragraph, or linked long-description.

If the image's role isn't obvious from context, make the most educated guess and commit to it.
Never ask a clarifying question: this skill runs non-interactively, so a question returns nothing the caller can use.

## Step 2: Write the Alt Text

**Skip "image of," "picture of," "photo of."** Screen readers already announce the element as an image.
Starting with "Image of a golden retriever" sounds like "image, image of a golden retriever" to the listener.
Just write "A golden retriever."

**Aim for roughly 125 characters, and treat 1,000 as a hard ceiling.** Around 125 is the long-standing practical
convention, and some screen readers truncate a few hundred characters in. Padding buys nothing. Complex images may
run past 125 when the content genuinely needs it, but prefer trimming to inflating.

**Match detail to purpose.** An article specifically about _Starry Night_ needs "Van Gogh's Starry Night:
swirling blues and yellows above a sleeping village." The same painting as unrelated background decoration on a
different site needs no alt text. The pixels are identical; the useful alt text is not.

**Transcribe text inside images.** Quote cards, memes, screenshots with visible UI text, and charts with labels.
The words matter to a screen-reader user exactly as much as they do to a sighted one.
Include them verbatim; don't paraphrase a quote or shorten a slogan, because the exact wording is usually the point.
Skip incidental branding like publisher watermarks unless they're meaningful.

**Text in a language other than the surrounding page.** Mirror what a sighted reader would experience.
On a page written in the same language as the image, transcribe in that language and stop. On a page written in a
different language whose readers likely don't speak the source, transcribe in the original _and_ add a brief gloss in
parentheses. Don't replace the original, because the text itself is often the artifact being discussed
(a sign, a vintage ad, a foreign-language screenshot).

**Meme and quote-card pattern.** Treat these as text-dominant: a brief description of the visible subject,
then the verbatim text, then the attribution. Something like "Bill Murray holding a microphone, next to a quote
attributed to him: '…' — Bill Murray." The image is scaffolding; the text is the content.

**Describe people by what's relevant, not what's visible.** Default to a name when known, role when relevant.
Age, race, gender, and appearance belong in the alt text only when they matter to understanding the content
(e.g., a historical photo in an article about segregation). Don't introduce them gratuitously.

**For charts and data visualizations, lead with the takeaway.** "Line chart showing revenue doubling from Q1 to Q4 2024"
beats "Line chart with four data points". The second description is technically accurate and practically useless.
Make the underlying numbers available elsewhere (data table, caption, long description) for readers who want detail.

**Avoid redundancy with nearby text.** If the caption directly below the image says "CEO Jane Doe speaking at the conference"
the alt text shouldn't repeat that. Either use empty alt text as the image is now effectively decorative relative to
the caption or describe something the caption doesn't.

## Step 3: Output Format

Return the alt text and nothing else: no preamble, no "Here's the alt text", no surrounding quotation marks, no
Markdown bold or code fences, no classification label, no rationale, no follow-up offer. Classification happens in
your head, not on the page. The response must paste straight into an `alt` attribute.

For a decorative image the entire response is `""` (two double-quote characters), signalling an empty alt attribute.

For multiple images, output one line per image in the form `<file name>: <alt text>`, reusing the file name exactly as
it was given to you. Key every line to its file name rather than to its position, so the caller can never pair an alt
text with the wrong image. Emit a line for every image you were given, decorative ones included
(`divider.png: ""`), never merge two images onto one line, and give each image the same care and level of detail you
would if it were the only one in the request. Output nothing besides those lines. If the user supplies
surrounding context (article topic, nearby paragraphs, the image's role), lean on it heavily. Context is the single
biggest lever for good alt text.

## Common Image Types — Quick Reference

| Image type                                   | Approach                                                                 |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| Logo in header (non-link)                    | Company name                                                             |
| Logo linking home                            | Company name (the link's destination is "home")                          |
| Icon button                                  | The action: "Close," "Search," "Menu," "Delete item"                     |
| Product photo in listing                     | Product identity + key visible details relevant to the decision          |
| Author head shot on bio                      | The person's name                                                        |
| Tutorial screenshot                          | What the screenshot is demonstrating                                     |
| Chart or graph                               | The finding, with raw data available elsewhere                           |
| Meme or quote card                           | Brief subject + verbatim text + attribution; skip watermarks             |
| Editorial photo of a sign, logo, or branding | Describe the artifact + transcribe any text (preserve original language) |
| Emoji in running text                        | Usually the standard name; skip if purely decorative                     |
| Photo illustrating an article                | The aspect of the article it illustrates                                 |
| Decorative pattern, divider, background      | Empty alt attribute (`alt=""`), never a missing one                      |

## What to Avoid

- Filler openings: "This image shows...", "In this picture...", "You can see..."
- Subjective adjectives the image alone can't support: "beautiful," "stunning," "inspiring"
- Keyword stuffing for SEO: alt text is for users, and modern search engines penalize it anyway
- Describing color, style, or composition unless they're the point
- Repeating the caption verbatim
- Writing alt text for decorative images just because the field exists

## Examples

**Example 1 — decorative divider**
Context: A thin ornamental line graphic between article sections.
Alt: ""

**Example 2 — product listing**
Context: E-commerce page, image of a red leather armchair.
Alt: "Red leather armchair with brass nail head trim and turned wooden legs"

**Example 3 — icon button**
Context: A magnifying-glass icon that triggers site search.
Alt: "Search"

**Example 4 — chart**
Context: Bar chart in a blog post about tech hiring, showing roles up 40% year-over-year with software leading.
Alt: "Bar chart: tech hiring rose 40% from 2024 to 2025, with software roles leading the growth"

**Example 5 — author headshot**
Context: Bio page, smiling photo of the author.
Alt: "Jane Doe"

**Example 6 — same photo, different context**
Context: News article about Jane Doe's keynote, with a caption reading "Jane Doe at the 2026 keynote."
Alt: ""
