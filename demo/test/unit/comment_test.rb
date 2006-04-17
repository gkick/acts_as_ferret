require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :comments

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Comment, comments(:first)
  end

  def test_class_index_dir
    assert_equal "#{RAILS_ROOT}/index/test/Comment", Comment.class_index_dir
  end

  # tests the automatic building of an index when none exists
  # delete index/test/* before running rake to make this useful
  def test_index_rebuild
    comments_from_ferret = Comment.find_by_contents('"comment from fixture"')
    assert_equal 2, comments_from_ferret.size
    assert comments_from_ferret.include?(comments(:first))
    assert comments_from_ferret.include?(comments(:another))
  end

  # tests the custom to_doc method defined in comment.rb
  def test_custom_to_doc
    top_docs = Comment.ferret_index.search('"comment from fixture"')
    assert_equal 2, top_docs.score_docs.size
    doc = Comment.ferret_index.doc(top_docs.score_docs[0].doc)
    # check for the special field added by the custom to_doc method
    assert_not_nil doc[:added]
    # still a valid int ?
    assert doc[:added].to_i > 0
  end

  def test_find_by_contents
    comment = Comment.new( :author => 'john doe', :content => 'This is a useless comment' )
    comment.save
    comment2 = Comment.new( :author => 'another', :content => 'content' )
    comment2.save

    comments_from_ferret = Comment.find_by_contents('anoth* OR jo*')
    assert_equal 2, comments_from_ferret.size
    assert comments_from_ferret.include?(comment)
    assert comments_from_ferret.include?(comment2)
    
    comments_from_ferret = Comment.find_by_contents('another')
    assert_equal 1, comments_from_ferret.size
    assert_equal comment2.id, comments_from_ferret.first.id
    
    comments_from_ferret = Comment.find_by_contents('doe')
    assert_equal 1, comments_from_ferret.size
    assert_equal comment.id, comments_from_ferret.first.id
    
    comments_from_ferret = Comment.find_by_contents('useless')
    assert_equal 1, comments_from_ferret.size
    assert_equal comment.id, comments_from_ferret.first.id
  
    # no monkeys here
    comments_from_ferret = Comment.find_by_contents('monkey')
    assert comments_from_ferret.empty?
    
    # multiple terms are ANDed by default...
    comments_from_ferret = Comment.find_by_contents('monkey comment')
    assert comments_from_ferret.empty?
    # ...unless you connect them by OR
    comments_from_ferret = Comment.find_by_contents('monkey OR comment')
    assert_equal 3, comments_from_ferret.size
    assert comments_from_ferret.include?(comment)
    assert comments_from_ferret.include?(comments(:first))
    assert comments_from_ferret.include?(comments(:another))

    # multiple terms, each term has to occur in a document to be found, 
    # but they may occur in different fields
    comments_from_ferret = Comment.find_by_contents('useless john')
    assert_equal 1, comments_from_ferret.size
    assert_equal comment.id, comments_from_ferret.first.id
    

    # search for an exact string by enclosing it in "
    comments_from_ferret = Comment.find_by_contents('"useless john"')
    assert comments_from_ferret.empty?
    comments_from_ferret = Comment.find_by_contents('"useless comment"')
    assert_equal 1, comments_from_ferret.size
    assert_equal comment.id, comments_from_ferret.first.id

    comment.destroy
    comment2.destroy
   end

end