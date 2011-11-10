#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class AccountDeletion < ActiveRecord::Base
  belongs_to :person
  after_create :queue_delete_account

  def person=(person)
    self.diaspora_id = person.diaspora_handle
    self[:person] = person
  end

  def queue_delete_account
    Resque.enqueue(Jobs::DeleteAccount, self.id)
  end
  
  def perform!
    AccountDeleter.new(self.diaspora_id).perform!
    self.dispatch
  end

  def dispatch

  end
end
