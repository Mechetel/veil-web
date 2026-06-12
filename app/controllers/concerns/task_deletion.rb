# Shared destroy / destroy_all / bulk_destroy for the task controllers
# (embeddings, decodings, analyses). Hooks a controller can override:
#
#   deletion_scope          — Current.user.<collection> (default from controller name)
#   human_record_name       — flash wording ("Encoding" for embeddings)
#   records_container       — DOM id emptied by destroy_all (default: controller name)
#   records_index_path      — where a show-page delete (?redirect=1) lands
#   bulk_records            — records selected by the bulk form params
#   removal_streams(records)— Turbo Streams that remove a record everywhere it appears
module TaskDeletion
  extend ActiveSupport::Concern

  def destroy
    record = deletion_scope.find(params[:id])
    record.destroy
    return redirect_to(records_index_path, notice: "#{human_record_name} deleted") if params[:redirect].present?

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "#{human_record_name} deleted"
        render turbo_stream: removal_streams([ record ]) + [ flash_stream ]
      end
      format.html { redirect_to root_path, notice: "#{human_record_name} deleted" }
    end
  end

  def bulk_destroy
    records = bulk_records
    records.each(&:destroy)
    flash.now[:notice] = "Deleted #{records.size} #{human_record_name.downcase.pluralize(records.size)}"
    respond_to do |format|
      format.turbo_stream { render turbo_stream: removal_streams(records) + [ flash_stream ] }
      format.html { redirect_back fallback_location: root_path, notice: flash.now[:notice] }
    end
  end

  def destroy_all
    deletion_scope.destroy_all
    notice = "All #{human_record_name.downcase.pluralize} deleted"
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice
        render turbo_stream: [ turbo_stream.update(records_container, ""), flash_stream ]
      end
      format.html { redirect_to root_path, notice: notice }
    end
  end

  private

  def deletion_scope = Current.user.public_send(controller_name)
  def human_record_name = controller_name.singularize.titleize
  def records_container = controller_name
  def records_index_path = public_send("#{controller_name}_path")

  def bulk_records
    ids = Array(params["#{controller_name.singularize}_ids"]).compact_blank
    deletion_scope.where(id: ids).to_a
  end

  def removal_streams(records)
    records.map { |r| turbo_stream.remove(r) }
  end
end
