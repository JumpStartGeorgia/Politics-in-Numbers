module Admin
  # Controls user resource actions
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :destroy]
    authorize_resource

    before_action :authorize_role_param, only: [:update]

    # GET /users
    # GET /users.json
    def index
      @users = User.all.includes(:role).order(:email)
    end

    # GET /users/1
    # GET /users/1.json
    def show
    end

    # GET /users/new
    def new
      @user = User.new
    end

    # GET /users/1/edit
    def edit
    end

    # POST /users
    # POST /users.json
    def create
      @user = User.new(user_params)

      respond_to do |format|
        if @user.save
          redirect_to_created_user(format)
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /users/1
    # PATCH/PUT /users/1.json
    def update
      respond_to do |format|
        if user_params[:password].present?
          update_user_with_password(format)
        else
          update_user_without_password(format)
        end
      end
    end

    # DELETE /users/1
    # DELETE /users/1.json
    def destroy
      @user.destroy
      respond_to do |format|
        format.html do
          redirect_to users_url,
                      notice: t('shared.msgs.success_destroyed',
                                obj: t('activerecord.models.user', count: 1))
        end
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the
    # white list through.
    def user_params
      params.require(:user).permit(:email, :password, :role_id)
    end

    def authorize_role_param
      not_authorized if cannot? :create, User.new(user_params)
    end

    def redirect_to_created_user(format)
      format.html do
        redirect_to [:admin, @user],
                    notice: t('shared.msgs.success_created',
                              obj: t('activerecord.models.user', count: 1))
      end
    end
    private :redirect_to_created_user

    def update_user_with_password(format)
      if @user.update(user_params)
        format.html do
          redirect_to [:admin, @user],
                      notice: t('shared.msgs.success_updated',
                                obj: t('activerecord.models.user', count: 1))
        end
      else
        format.html { render :edit }
      end
    end
    private :update_user_with_password

    def update_user_without_password(format)
      if @user.update_without_password(user_params)
        format.html do
          redirect_to [:admin, @user],
                      notice: t('shared.msgs.success_updated',
                                obj: t('activerecord.models.user', count: 1))
        end
      else
        format.html { render :edit }
      end
    end
  end
end
