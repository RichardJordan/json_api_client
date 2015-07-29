require 'test_helper'

class SerializingTest < MiniTest::Test

  class LimitedField < TestResource
    self.read_only_attributes += ['foo']
  end

  class CustomSerializerAttributes < TestResource

    protected

    def attributes_for_serialization
      {
        foo: "bar"
      }
    end
  end

  class InheritedCustomSerializerAttributes < TestResource

    protected

    def attributes_for_serialization
      super.except(:foo)
    end
  end

  def test_as_json_api
    expected = {
      'type' => 'articles',
      'attributes' => {
        'foo' => 'bar',
        'qwer' => 'asdf'
      }
    }

    article = Article.new(foo: 'bar', qwer: 'asdf')
    assert_equal expected, article.as_json_api
  end

  def test_as_json_api_with_relationships
    expected = {
      'type' => 'articles',
      'attributes' => {
        'foo' => 'bar',
        'qwer' => 'asdf'
      },
      'relationships' => {
        'author' => {
          'data' => {
            'type' => 'people',
            'id' => 123
          }
        }
      }
    }

    article = Article.new(foo: 'bar', qwer: 'asdf')
    article.relationships.author = Person.new(id: 123, name: 'Bob')

    assert_equal expected, article.as_json_api
  end

  def test_update_data_only_includes_relationship_data
    stub_request(:get, "http://example.com/articles")
      .to_return(headers: {content_type: "application/vnd.api+json"}, body: {
        data: [{
          type: "articles",
          id: "1",
          attributes: {
            title: "JSON API paints my bikeshed!"
          },
          relationships: {
            author: {
              links: {
                self: "http://example.com/posts/1/relationships/author",
                related: "http://example.com/posts/1/author"
              },
              data: {
                type: "people",
                id: "9"
              }
            }
          }
        }],
        included: [{
          type: "people",
          id: "9",
          attributes: {
            name: "Jeff"
          }
        }]
      }.to_json)

    articles = Article.all
    article = articles.first

    expected = {
      "type" => "articles",
      "id" => "1",
      "attributes" => {}
    }
    assert_equal expected, article.as_json_api
  end

  def test_update_data_only_includes_relationship_data_with_all_attributes_dirty
    stub_request(:get, "http://example.com/articles")
        .to_return(headers: {
                       content_type: "application/vnd.api+json"},
                   body: {
                       data: [{
                                  type: "articles",
                                  id: "1",
                                  attributes: {
                                      title: "JSON API paints my bikeshed!"
                                  },
                                  relationships: {
                                      author: {
                                          links: {
                                              self: "http://example.com/posts/1/relationships/author",
                                              related: "http://example.com/posts/1/author"
                                          },
                                          data: {
                                              type: "people",
                                              id: "9"
                                          }
                                      }
                                  }
                              }],
                       included: [{
                                      type: "people",
                                      id: "9",
                                      attributes: {
                                          name: "Jeff"
                                      }
                                  }]
                   }.to_json)

    articles = Article.all
    article = articles.first
    article.set_all_dirty!

    expected = {
        "type" => "articles",
        "id" => "1",
        "attributes" => {
            "title" => "JSON API paints my bikeshed!"
        },
        "relationships" => {
            "author" => {
                "data" => {
                    "type" => "people",
                    "id" => "9"
                }
            }
        }
    }
    assert_equal expected, article.as_json_api
  end

  def test_skips_read_only_attributes
    resource = LimitedField.new({
      id: 1,
      foo: "bar",
      qwer: "asdf"
    })

    expected = {
      'id' => 1,
      'type' => 'limited_fields',
      'attributes' => {
        'qwer' => 'asdf'
      }
    }
    assert_equal(expected, resource.as_json_api)
  end

  def test_can_specify_attributes_for_serialization
    resource = CustomSerializerAttributes.new

    expected = {
      "type" => "custom_serializer_attributes",
      "attributes" => {
        "foo" => "bar"
      }
    }
    assert_equal expected, resource.as_json_api
  end

  def test_inherited_attributes_for_serialization
    resource = InheritedCustomSerializerAttributes.new({
      foo: "bar",
      id: 1234,
      qwer: "asdf"
    })

    expected = {
      "type" => "inherited_custom_serializer_attributes",
      "id" => 1234,
      "attributes" => {
        "qwer" => "asdf"
      }
    }

    assert_equal expected, resource.as_json_api
  end

end