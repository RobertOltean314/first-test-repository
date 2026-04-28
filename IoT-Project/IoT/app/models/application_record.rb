class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def hello
    render html: "Hello World!"
  end
end
