class PostsController < ApplicationController
	before_action :set_post, only: [:show,:edit,:update,:delete]
	def index
		@posts = current_user.posts
	end
	def show
		
	end
	def new
		@post = current_user.posts.build
	end	
	def create
		@post = current_user.posts.build(post_params)
		if @post.save
			redirect_to post_path(@post)
		else
			render 'new'
		end
	end
	def edit
	
	end
	def update
		if @post.update(post_params)
			redirect_to post_path(@post)
		else
			render 'edit'
		end
	end
	def delete
		if @post.destroy
			redirect_to post_path(@post)
		else
			render 'edit'
		end
	end
	protected
		def set_post
			@post = Post.find(params[:id])
		end
		def post_params
			params.require(:post).permit(:title,:desc)
		end

end
