require "#{RAILS_ROOT}/lib/activerecord/custom_nested_attributes.rb"
class Contract < ActiveRecord::Base

  include ActiveRecord::CustomNestedAttributes
  include SSM
  
  ssm_inject_state_into :state, :as_integer => true, :strategy => :active_record
  
  ssm_initial_state :open
  ssm_state :active
  ssm_state :closed

  # ssm_event :start, :from => [:open], :to => :active do
  # end
  # 
  # ssm_event :close, :from => [:open, :active], :to => :close do
  # end
  
  belongs_to :user
  belongs_to :posted_by, :class_name => "User", :foreign_key => "posted_by_user_id"
  belongs_to :position
  belongs_to :city
  
  belongs_to :contract_type
  belongs_to :contract_periodicity_type
  belongs_to :contract_rate_type
  
  has_many :applications, :class_name => "JobApplication", :include => :applicant
  has_many :applicants, :through => :applications
  
  validates_presence_of :position
  custom_accepts_nested_attributes_for :position
  
  named_scope :current, lambda {{:conditions => "user_id IS NOT NULL AND (contracts.to > '#{Time.now.utc}' OR contracts.to IS NULL)"}}
  named_scope :open ,   :conditions => "user_id IS NULL", :order => "updated_at DESC"
  
  # services
  def opening_service; @opening_service ||= OpeningService.new(self); end
  
  def from=(attributes)
    if attributes[:start_asap].present?
      self[:from] = DateTime.now.utc
    elsif attributes[:month] and attributes[:year]
      self[:from] = DateTime.parse("#{attributes[:year]}-#{attributes[:month]}-01")
    else
      self[:from] = nil
    end
  end
  
  def to=(attributes)
    if attributes[:month] and attributes[:year] and !attributes[:open_ended].present?
      self[:to] = DateTime.parse("#{attributes[:year]}-#{attributes[:month]}-01")
    else
      self[:to] = nil
    end
  end
  
  def started_on_as_datetime
    raise
    DateTime.parse("#{from_year}-#{from_month}-01")
  end
  
  def description=(text)
    self[:description] = RedCloth.new(text || "")
    self[:description].sanitize_html = true
  end
  
  def benefits=(text)
    self[:benefits] = RedCloth.new(text || "")
    self[:benefits].sanitize_html = true
  end
  
end
