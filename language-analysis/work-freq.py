from textblob import TextBlob
import click
import PyPDF2
from collections import Counter

# trying to avoid 'unescaped string' printed msgs
# import warnings
# warnings.filterwarnings("ignore")
# import logging
# logger = logging.getLogger("pypdf")
# logger.setLevel(logging.ERROR)

def extract_text_from_pdf(pdf_path):
    text = ""
    with open(pdf_path, "rb") as f:
        reader = PyPDF2.PdfReader(f)
        for page in reader.pages:
            text += "\n" + (page.extract_text() or "")
    return text

def print_tags(tb: TextBlob):
    print(f"#> Tags (word, POS): {len(tb.tags)}")
    print("Not printing everything cause it's lots and uninteresting")
    # for word, tag in tb.tags:
    #     print(f"{word}: {tag}")

def print_word_frequencies(tb: TextBlob, top_n: int = 50):
    words: list[str] = [word.lower() for word in tb.words if word.isalpha()]
    freq = Counter(words)
    print(f"#> Word Frequencies (word, count): Top {top_n}")
    skip_words = {'s', 'the', 'and', 'to', 'of', 'a', 'in', 'is', 'that', 'it', 'for', 'this', 'with', 'as', 'on', 'was', 'are', 'by', 'at'}
    nb_extra = len(skip_words)
    count_printed = 0
    for word, count in freq.most_common(top_n + nb_extra):
        if word in skip_words:
            continue
        print(f" | {word}: {count}", end=" ")
        count_printed += 1
        if count_printed >= top_n:
            break
    print()
    click.echo(f"Number of words & unique in TextBlob: {len(tb.words)}, {len(set(words))}")

def print_noun_phrase_frequencies(tb: TextBlob, top_n: int = 50):
    '''This is pretty slow.'''
    # phrases: list[str] = []
    phrases = [phrase.lower() for phrase in tb.noun_phrases if phrase.isalpha()]
    freq = Counter(phrases)
    print(f"#> Noun Phrase Frequencies (phrase, count): Top {top_n}")
    skip_phrases = {'the', 'and', 'to', 'of', 'a', 'in', 'is', 'that', 'it', 'for', 'this', 'with', 'as', 'on', 'was', 'are', 'by', 'at'}
    nb_extra = len(skip_phrases)
    count_printed = 0
    for phrase, count in freq.most_common(top_n + nb_extra):
        if phrase in skip_phrases:
            continue
        print(f"  {phrase}: {count}")
        count_printed += 1
        if count_printed >= top_n:
            break


@click.command()
@click.argument('pdf_path', type=click.Path(exists=True)) #, help="Path to the PDF file to analyze")
@click.option('--tags', '-t', is_flag=True, help='Print tags from TextBlob analysis')
@click.option('--sentiment', '-s', is_flag=True, help='Print sentiment analysis from TextBlob')
@click.option('--top-n', '-n', default=50, help='Number of top word frequencies to display')
@click.option('--noun-phrases', '-p', is_flag=True, help='(SLOW) Print noun phrase frequencies from TextBlob analysis')
def main(pdf_path, tags, sentiment, top_n, noun_phrases):
    """Analyze a PDF file for word frequency and optionally print tags."""
    click.echo(f"Processing PDF file: {pdf_path}")
    pdf_text = extract_text_from_pdf(pdf_path)
    click.echo(f"Extracted text from PDF. Length: {len(pdf_text)}. Now analyzing word frequency...")
    tb = TextBlob(pdf_text)
    if tags: print_tags(tb)
    print_word_frequencies(tb, top_n)
    if noun_phrases: print_noun_phrase_frequencies(tb, top_n)
    click.echo(f"Number of sentences in TextBlob: {len(tb.sentences)}")
    if sentiment:
        click.echo(f"#> Sentiment: {tb.sentiment}")
        click.echo(f"  Polarity: {tb.sentiment.polarity}, Subjectivity: {tb.sentiment.subjectivity}")
    click.echo("Analysis complete.")

if __name__ == '__main__':
    main()
