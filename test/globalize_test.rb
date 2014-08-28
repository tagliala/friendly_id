# encoding: utf-8

require "helper"

class TranslatedArticle < ActiveRecord::Base
  translates :slug, :title
  extend FriendlyId
  friendly_id :title, :use => :globalize
end

class GlobalizeTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  def setup
    I18n.locale = :en
  end

  test "should find slug in current locale if locale is set, otherwise in default locale" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { TranslatedArticle.create(:title => 'a title') }
      article_de = I18n.with_locale(:de) { TranslatedArticle.create(:title => 'titel') }

      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.find("titel"), article_de
        assert_equal TranslatedArticle.find("a-title"), article_en
      }
    end
  end

  test "should set friendly id for locale" do
    transaction do
      article = TranslatedArticle.create!(:title => "War and Peace")
      article.set_friendly_id("Guerra y paz", :es)
      article.save!
      article = TranslatedArticle.find('war-and-peace')
      I18n.with_locale(:es) { assert_equal "guerra-y-paz", article.friendly_id }
      I18n.with_locale(:en) { assert_equal "war-and-peace", article.friendly_id }
    end
  end

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by friendly_id should have all translations" do
    transaction do
      I18n.with_locale(:en) do
        article = TranslatedArticle.create(:title => 'a title')
        Globalize.with_locale(:ja) { article.update_attributes(:title => 'タイトル') }
        article_by_friendly_id = TranslatedArticle.find("a-title")
        article.translations.each do |translation|
          assert_includes article_by_friendly_id.translations, translation
        end
      end
    end
  end

  test "should find slug in any locale when slugs for more than one locale has been filled" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { TranslatedArticle.create(:title => 'a title') }
      I18n.with_locale(:de) { article_en.title = 'titel'; article_en.save! }

      assert_equal TranslatedArticle.find("a-title"), article_en

      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.find("titel"), article_en
      }
    end
  end

  test "should find slug collisions when slugs for more than one locale has been filled" do
    transaction do
      I18n.default_locale = :en

      first_article = TranslatedArticle.create(:title => 'a title')
      second_article = TranslatedArticle.create(:title => 'a title')
      I18n.with_locale(:de) { first_article.title = 'titel'; first_article.save! }
      I18n.with_locale(:de) { second_article.title = 'titel'; second_article.save! }

      assert_equal "a-title", first_article.slug
      assert_equal "a-title--2", second_article.slug
      I18n.with_locale(:de) {
        assert_equal "titel", first_article.slug
        assert_equal "titel--2", second_article.slug
      }
    end
  end

  test "should find slug collisions when slugs for more than one locale has been filled (2)" do
    transaction do
      I18n.default_locale = :en

      first_article = TranslatedArticle.create(:title => 'a title')
      I18n.with_locale(:de) { first_article.title = 'titel'; first_article.save! }
      second_article = TranslatedArticle.create(:title => 'a title')
      I18n.with_locale(:de) { second_article.title = 'titel'; second_article.save! }

      assert_equal "a-title", first_article.slug
      assert_equal "a-title--2", second_article.slug
      I18n.with_locale(:de) {
        assert_equal "titel", first_article.slug
        assert_equal "titel--2", second_article.slug
      }
    end
  end

  test "should find the article in the active locale" do
    transaction do
      I18n.default_locale = :en

      first_article = TranslatedArticle.create(:title => 'titel')
      second_article = TranslatedArticle.create(:title => 'a title')
      I18n.with_locale(:de) { second_article.title = 'titel'; second_article.save! }

      assert_equal TranslatedArticle.find("titel"), first_article
      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.find("titel"), second_article
      }
    end
  end
end
