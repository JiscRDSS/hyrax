module Sufia
  module SingleUseLinksControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::SearchHelper
    included do
      class_attribute :show_presenter
      self.show_presenter = Sufia::SingleUseLinkPresenter
      before_action :authenticate_user!
      before_action :authorize_user!
      # Catch permission errors
      rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
        if current_user && current_user.persisted?
          redirect_to main_app.root_url, alert: "You do not have sufficient privileges to create links to this document"
        else
          session["user_return_to"] = request.url
          redirect_to main_app.new_user_session_url, alert: exception.message
        end
      end
    end

    def create_download
      @su = SingleUseLink.create itemId: params[:id], path: sufia.download_path(id: params[:id])
      render plain: sufia.download_single_use_link_url(@su.downloadKey)
    end

    def create_show
      @su = SingleUseLink.create(itemId: params[:id], path: asset_show_path)
      render plain: sufia.show_single_use_link_url(@su.downloadKey)
    end

    def index
      links = SingleUseLink.where(itemId: params[:id]).map { |link| show_presenter.new(link) }
      render partial: 'sufia/file_sets/single_use_link_rows', locals: { single_use_links: links }
    end

    def destroy
      SingleUseLink.find_by_downloadKey(params[:link_id]).destroy
      head :ok
    end

    protected

      def authorize_user!
        authorize! :edit, params[:id]
      end

      def asset_show_path
        polymorphic_path([main_app, fetch(params[:id]).last])
      end
  end
end
