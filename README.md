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


### eReader Tool - BookWyrm
The idea is if we can solve this for ebooks, we likely can take the learnings from that and apply it to more "complex" sources. These might have more disperate ideas, less linear learning etc, so the MVP is solving this for "good books".

- User uploads
    - Upload an ebook (epub, html, text, maybe pdf)
- Tool parses that data to make micro learnings
    - Parse the chapters or subjects in to time chunks.
    - Review the content to prepare review questions/internal summary of the content.
- Before you read, the tool could detect where you should start via a review quiz.
- User asks to learn some amount for some frequency
- Allow user to take notes during reading sessions
    - Review the user's notes for any missed core ideas
    - Quiz the user on what they didn't write down
- Keep track of user streak and total progress



### Technical Deliverables
#### P0
- File manager for ebooks
    - Parse ebook formats
- API calls to the LLM of choice
- API calls to generate review questions
- User state managment

#### P1
- Note taking source to do review

#### P2
- Account Management