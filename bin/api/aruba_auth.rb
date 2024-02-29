# frozen_string_literal: true

#######################################################################
# Copyright (c) 2023 ENEO Tecnologia S.L.
# This file is part of redBorder.
# redBorder is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# redBorder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with redBorder. If not, see <http://www.gnu.org/licenses/>.
#######################################################################

#
# Class for handle the refresh token of the rb-arubacentral
#
class ArubaAuthRefresher
  def refresh_oauth_token
    @log_controller.info('Refreshing oauth_token...')
    @self_token = oauth(
      @gateway,
      @username,
      @password,
      @client_id,
      @client_secret,
      @client_customer_id
    )['access_token']
  end
end
