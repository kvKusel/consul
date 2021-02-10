require_dependency Rails.root.join("app", "models", "debate").to_s
class Debate < ApplicationRecord
  MANAGE_CATEGORIES    = 0b010
  MANAGE_SUBCATEGORIES = 0b010

  TAGS_PREDEFINED = 0b001
  TAGS_CLOUD      = 0b010
  TAGS_CUSTOM     = 0b100
end