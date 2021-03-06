class Contests::AttemptsController < ApplicationController
  helper 'contests/surveys'
  before_filter :authenticate_user! 
  before_filter :load_survey
  #load_and_authorize_resource
  before_filter :normalize_attempts_data, :only => :create
  
  def new
    @participant = current_user
    @theory = Theory.where(id: @survey.theory_id).first
    @article = Article.where(id: @survey.article_id).first
    @vocabulary = Vocabulary.where(id: @survey.vocabulary_id).first
    @surveys = Survey::Survey.where("theory_id = ? OR article_id = ? OR vocabulary_id = ?", @survey.theory_id, @survey.article_id, @survey.vocabulary_id) 
    @user = User.where(id: @survey.user_id).first
    unless @survey.nil?
      @attempt = @survey.attempts.new
      @attempt.answers.build
    end
  end

  def show
    @attempt = Survey::Attempt.find_by(id: params[:id])
    render :access_error if current_user.id != @attempt.participant_id
  end

  def create
    @attempt = @survey.attempts.new(attempt_params)
    @attempt.participant = current_user
    if @attempt.valid? && @attempt.save
      redirect_to view_context.attempt_path(@attempt.id), alert: "Sprawdź swój wyniki! Prawidłowe opowiedzi zostały zaznaczone na zielono, a błędne- na czerwono."
    else
      render :action => :show
    end
  end

  private

    def load_survey
      @survey = Survey::Survey.find_by(id: params[:survey_id])
    end

    def normalize_attempts_data
      normalize_data!(params[:survey_attempt][:answers_attributes])
    end

    def normalize_data!(hash)
      multiple_answers = []
      last_key = hash.keys.last.to_i

      hash.keys.each do |k|
        if hash[k]['option_id'].is_a?(Array)
          if hash[k]['option_id'].size == 1
            hash[k]['option_id'] = hash[k]['option_id'][0]
            next
          else
            multiple_answers <<  k if hash[k]['option_id'].size > 1
          end
        end
      end

      multiple_answers.each do |k|
        hash[k]['option_id'][1..-1].each do |o|
          last_key += 1
          hash[last_key.to_s] = hash[k].merge('option_id' => o)
        end
        hash[k]['option_id'] = hash[k]['option_id'].first
      end
    end

    def attempt_params
      rails4? ? params_whitelist : params[:survey_attempt]
    end

    def params_whitelist
      if params[:survey_attempt]
        params[:survey_attempt][:answers_attributes] = params[:survey_attempt][:answers_attributes].map { |attrs| { question_id: attrs.first, option_id: attrs.last } }
        params.require(:survey_attempt).permit(Survey::Attempt::AccessibleAttributes)
      end
end
end