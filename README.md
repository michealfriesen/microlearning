# microlearning
Making learning short and fun.

## Running App
Ensure you have flutter installed and have no issues when running
```bash
flutter doctor
```

After this, you should be able to run the base project on your default device via
```bash
flutter run
```

# Goals

- Don't rob the user of the experience of learning by doing the work for them
- Supplement rather than replace other mediums of learning and information tracking
- Add some amount of accountability & reward for doing the work

# Book Summarization

The goal here is to avoid sending the whole book to the remote LLM to generate quiz questions
and the like. Want to instead do some local processing to distill the text down to essential
information.

Nice bit here is that none of this requires a UI and can be worked on independently.

Text is organized in hierachies which we can use to our advantage. Things that we can do sans
LLM are
- [ ] Table of contents search & indexing - Technical books at least have ToC and appendices. Use that as the first level of splitting up the book for the user
- [ ] Book summary extraction - Often technical books will end chapters with summaries of the material along with questions & exercises to enrich the learning
- [ ] Heading, subheading organization - chunk chapters up by their headings
- [ ] Extraneous styling removal - Most styling is unlikely to be relevant to the LLM other than perhaps bold & italics. Convert the original format into something more compact for the LLM to consume. Commonmark is probably the best target for this since there's A LOT of markdown on the internet
- [ ] Time to read estimation - impl a time to read algorithm to give a first pass of effort required to read information
    - Could reference [this meta analysis](https://www.researchgate.net/publication/332380784_How_many_words_do_we_read_per_minute_A_review_and_meta-analysis_of_reading_rate) for how to compute this stuff. Doesn't include code however

Then with the local LLM
- [ ] Progressive extraction - Similar to how humans take notes extract quotes that have the most pertinent information without generating new sentences and link where they came from
- [ ] Summarization - Take the extracted information and summarize it
- [ ] Vectorization - Some interesting techniques involve converting the information into high dimensional vectors. Don't know enough about this area to know what it's good for

(stretch) If the user takes notes, we could take that information and do some interesting things in conjunction with the summarization that the LLM is making
- [ ] Missing important information check
- [ ] Correctness checks (use book as source of truth)
- [ ] Long form questions

(stretch) Again if the user takes notes, we could do some interesting things in their notes applications that automate some of the note taking drudgery
- [ ] Note APP MCP server integration
- [ ] Auto generate note taking systems templates

Then with either the local LLM or a more powerful remote LLM
- [ ] Take summaries relevant to the section & generate quiz questions to check the user's learning
- [ ] Use summaries to get LLM to estimate learning effort required to grok the new information
- [ ] Take summaries and try to relate it to information already seen by the user

Packages that would support this are
- https://pub.dev/packages/ollama
- https://ollama.com/ <- Easy way to get LLMs locally
- https://github.com/ggml-org/llama.cpp <- Unsure why this would be desired over Ollama
- https://docs.turso.tech/introduction <- For storing the summaries & embeddings

References
- [this article](https://spraphul.github.io/blog/book-summary) for the methodology.
- [this article](https://fortelabs.com/blog/progressive-summarization-a-practical-technique-for-designing-discoverable-notes/) for an effective way that humans take notes
- [this article](https://e-student.org/note-taking-methods/) for other common note taking methodologies. It's worth noting that humans seem to need multimodal learning resources. Text is likely sufficient for the LLM
- [this article](https://e-student.org/reap-note-taking-method/) about the REAP method which we may want to encourage the reader to use while they read the text

# Ui/Ux Ideas

- Can we borrow some ideas from Duolingo to keep folks coming back?
    - Streaks
    - Guilt trip reminders
    - Celebration of completion
- Can we make the journey through the book visual & appealing?
    - Roadmap
    - Mind maps
- Can we show how much the user has learned at different points through the book?
    - Visual representations of information quantity (skill trees, attribute diagrams, heat maps)
    - Reminders of what you tackled
    - Projections of progress if the user makes tiny incremental steps often
- How can we ensure that the users remember the information that they've just learned?
    - Flash cards for terms and concepts
    - Pop quizzes
    - Weekly summary of information
    - Information from last time at a glance

