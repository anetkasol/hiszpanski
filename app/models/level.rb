class Level < ActiveRecord::Base
# poxiomy do kategorii gramatyka
	has_many :theories, dependent: :destroy

	has_many :articles, dependent: :destroy
end
