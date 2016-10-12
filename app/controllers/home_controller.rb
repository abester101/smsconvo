class HomeController < ApplicationController
  def hardboundvcf
    @phone = params[:phone]
    render vcard: 'hardboundvcf'
  end
end