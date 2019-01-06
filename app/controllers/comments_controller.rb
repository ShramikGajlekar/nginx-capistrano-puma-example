class CommentsController < ApplicationController
	before_action :set_post, only: [:create,:edit,:update,:destroy]
	before_action :set_comment, only: [:edit,:update,:destroy]

	def create
		@comment = @post.comments.build(comment_params)
		@comment.user_id = current_user.id
		if @comment.save
			redirect_to post_path(@post)
		else
			redirect_to post_path(@post)
		end
	end
	def edit
	end
	def update
		if @comment.update(comment_params)
			redirect_to post_path(@post)
		else
			redirect_back fallback_location: post_path(@post)
		end
	end
	def destroy
		if @comment.destroy
			redirect_to post_path(@post)
		else
			redirect_back fallback_location: post_path(@post)
		end
	end
	protected
		def set_comment
			@comment = Comment.find(params[:id])
		end
		def set_post
			@post = Post.find(params[:post_id])
		end
		def comment_params
			params.require(:comment).permit(:body)
		end

end
