require 'test_helper'

context "Paragraphs" do
  test "rendered correctly" do
    assert_xpath "//p", render_string("Plain text for the win.\n\nYes, plainly."), 2
  end

  test "with title" do
    rendered = render_string(".Titled\nParagraph.\n\nWinning")
    
    assert_xpath "//div[@class='title']", rendered
    assert_xpath "//p", rendered, 2
  end

  test "no duplicate block before next section" do
    rendered = render_string("Title\n=====\n\nPreamble.\n\n== First Section\n\nParagraph 1\n\nParagraph 2\n\n\n== Second Section\n\nLast words")
    assert_xpath '//p[text()="Paragraph 2"]', rendered, 1
  end

  context "code" do
    test "single-line literal paragraphs" do
      output = render_string("    LITERALS\n\n    ARE LITERALLY\n\n    AWESOMMMME.")
      assert_xpath "//pre/tt", render_string("    LITERALS\n\n    ARE LITERALLY\n\n    AWESOMMMME.")
    end

    test "multi-line literal paragraph" do
      input = <<-EOS
Install instructions:

 yum install ruby rubygems
 gem install asciidoctor

You're good to go!
      EOS
      # TODO push this into the render_string helper, but need to update assertions to deal w/ endlines
      output = Asciidoctor::Document.new(input.lines.entries).render
      assert_xpath "//pre/tt", output, 1
      assert_match /^gem install asciidoctor/, output, "Indendation should be trimmed from literal block"
    end

    test "listing paragraph" do
      assert_xpath "//div[@class='highlight']", render_string("----\nblah blah blah\n----")
    end

    test "source code paragraph" do
      assert_xpath "//div[@class='highlight']", render_string("[source, perl]\ndie 'zomg perl sucks';")
    end
  end

  context "quote" do
    test "quote block" do
      output = render_string("____\nFamous quote.\n____")
      assert_xpath '//*[@class = "quoteblock"]', output, 1
      assert_xpath '//*[@class = "quoteblock"]//p[text() = "Famous quote."]', output, 1
    end

    test "quote block with attribution" do
      output = render_string("[quote, A famous person, A famous book]\n____\nFamous quote.\n____")
      assert_xpath '//*[@class = "quoteblock"]', output, 1
      assert_xpath '//*[@class = "quoteblock"]/*[@class = "attribution"]', output, 1
      assert_xpath '//*[@class = "quoteblock"]/*[@class = "attribution"]/em[text() = "A famous book"]', output, 1
      # TODO I can't seem to match the attribution (author) w/ xpath
    end

    test "quote block with section body" do
      output = render_string("____\nFamous quote.\n\nNOTE: That was inspiring.\n____")
      assert_xpath '//*[@class = "quoteblock"]', output, 1
      assert_xpath '//*[@class = "quoteblock"]//*[@class = "admonitionblock"]', output, 1
    end

    test "single-line quote paragraph" do
      output = render_string("[quote]\nFamous quote.")
      assert_xpath '//*[@class = "quoteblock"]', output, 1
      assert_xpath '//*[@class = "quoteblock"]//p', output, 0
    end

    test "verse paragraph" do
      output = render_string("[verse]\nFamous verse.")
      assert_xpath '//*[@class = "verseblock"]', output, 1
      assert_xpath '//*[@class = "verseblock"]/pre', output, 1
      assert_xpath '//*[@class = "verseblock"]//p', output, 0
      assert_xpath '//*[@class = "verseblock"]/pre[normalize-space(text()) = "Famous verse."]', output, 1
    end

    test "single-line verse block" do
      output = render_string("[verse]\n____\nFamous verse.\n____")
      assert_xpath '//*[@class = "verseblock"]', output, 1
      assert_xpath '//*[@class = "verseblock"]/pre', output, 1
      assert_xpath '//*[@class = "verseblock"]//p', output, 0
      assert_xpath '//*[@class = "verseblock"]/pre[normalize-space(text()) = "Famous verse."]', output, 1
    end

    test "multi-line verse block" do
      output = render_string("[verse]\n____\nFamous verse.\n\nStanza two.\n____")
      assert_xpath '//*[@class = "verseblock"]', output, 1
      assert_xpath '//*[@class = "verseblock"]/pre', output, 1
      assert_xpath '//*[@class = "verseblock"]//p', output, 0
      assert_xpath '//*[@class = "verseblock"]/pre[contains(text(), "Famous verse.")]', output, 1
      assert_xpath '//*[@class = "verseblock"]/pre[contains(text(), "Stanza two.")]', output, 1
    end

    test "verse block does not contain block elements" do
      output = render_string("[verse]\n____\nFamous verse.\n\n....\nnot a literal\n....\n____")
      assert_xpath '//*[@class = "verseblock"]', output, 1
      assert_xpath '//*[@class = "verseblock"]/pre', output, 1
      assert_xpath '//*[@class = "verseblock"]//p', output, 0
      assert_xpath '//*[@class = "verseblock"]//*[@class = "literalblock"]', output, 0
    end
  end

  context "special" do
    test "note multiline syntax" do
      Asciidoctor::ADMONITION_STYLES.each do |style|
        assert_xpath "//div[@class='admonitionblock']", render_string("[#{style}]\nThis is a winner.")
      end
    end

    test "note block syntax" do
      Asciidoctor::ADMONITION_STYLES.each do |style|
        assert_xpath "//div[@class='admonitionblock']", render_string("[#{style}]\n====\nThis is a winner.\n====")
      end
    end

    test "note inline syntax" do
      Asciidoctor::ADMONITION_STYLES.each do |style|
        assert_xpath "//div[@class='admonitionblock']", render_string("#{style}: This is important, fool!")
      end
    end

    test "sidebar block" do
      input = <<-EOS
== Section

.Sidebar
****
Content goes here
****
      EOS
      result = render_string(input)
      assert_xpath "//*[@class='sidebarblock']//p", result, 1
    end
  end

  context "comments" do
    test "line comment" do
      assert_no_match /comment/, render_string("first paragraph\n\n//comment\n\nsecond paragraph")
    end

    test "comment block" do
      assert_no_match /comment/, render_string("first paragraph\n\n////\ncomment\n////\n\nsecond paragraph")
    end
  end
end
